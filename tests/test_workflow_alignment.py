"""Contract tests for GitHub Actions protected-environment and OIDC alignment."""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path
from typing import Any

import pytest
import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]
CD_WORKFLOW = REPO_ROOT / ".github" / "workflows" / "terraform-cd.yml"
README = REPO_ROOT / "README.md"


def _load_cd() -> dict[str, Any]:
    raw = yaml.safe_load(CD_WORKFLOW.read_text(encoding="utf-8"))
    assert isinstance(raw, dict)
    return raw


def test_documented_environments_align_with_workflow_dispatch_and_oidc_permissions() -> None:
    doc = README.read_text(encoding="utf-8")
    assert "`personal`" in doc and "`personal-apply`" in doc
    assert "custom_branch_policies = true" in doc and "`main` only" in doc
    assert "repo:buffingtonbr/llm-tools-infra:environment:personal" in doc
    assert "repo:buffingtonbr/llm-tools-infra:environment:personal-apply" in doc

    wf = _load_cd()
    triggers = wf.get("on") or wf.get(True)
    assert isinstance(triggers, dict) and set(triggers.keys()) == {"workflow_dispatch"}

    env_input = triggers["workflow_dispatch"]["inputs"]["environment"]
    assert env_input["type"] == "choice"
    assert env_input["options"] == ["personal"]
    assert env_input["default"] == "personal"

    assert wf["jobs"]["validate-action"]["if"] == "github.ref == 'refs/heads/main'"
    cd_job = wf["jobs"]["cd"]
    assert cd_job["if"] == "github.ref == 'refs/heads/main'"
    assert cd_job["needs"] == "validate-action"
    assert cd_job["uses"] == "BRBuffington/terraform-pipelines-github/.github/workflows/terraform-cd.yml@main"
    assert cd_job["permissions"]["id-token"] == "write"
    assert cd_job["permissions"]["contents"] == "read"
    assert cd_job["with"]["environment"] == "${{ inputs.environment || 'personal' }}"
    assert cd_job["with"]["configs"] == '${{ inputs.configs || \'["brb-llmtools-prd-eus"]\' }}'
    assert cd_job["with"]["pipelines_owner"] == "BRBuffington"
    assert cd_job["with"]["stamp_last_applied"] is False


@pytest.mark.parametrize(
    ("dispatch_ref", "target_env", "plan_only", "destroy", "confirm_action", "expect_ok"),
    [
        ("refs/heads/main", "personal", "true", "false", "", True),
        ("refs/heads/main", "personal", "false", "false", "", False),
        ("refs/heads/main", "personal", "false", "false", "APPLY", True),
        ("refs/heads/main", "personal", "true", "true", "", False),
        ("refs/heads/main", "personal", "false", "true", "APPLY", False),
        ("refs/heads/main", "personal", "false", "true", "DESTROY", True),
        ("refs/heads/main", "dev", "true", "false", "", False),
        ("refs/heads/main", "prod", "false", "false", "APPLY", False),
        ("refs/heads/feat/unreviewed", "personal", "true", "false", "", False),
        ("refs/heads/feat/unreviewed", "personal", "false", "false", "APPLY", False),
    ],
)
def test_validate_action_script_enforces_environment_and_confirmation_matrix(
    dispatch_ref: str,
    target_env: str,
    plan_only: str,
    destroy: str,
    confirm_action: str,
    expect_ok: bool,
) -> None:
    wf = _load_cd()
    script = wf["jobs"]["validate-action"]["steps"][0]["run"]
    valid_ref = dispatch_ref == "refs/heads/main"
    valid_env = target_env == "personal"
    valid_destroy = not (destroy == "true" and confirm_action != "DESTROY")
    valid_apply = not (plan_only == "false" and destroy != "true" and confirm_action != "APPLY")
    assert "$DISPATCH_REF" in script and "$TARGET_ENV" in script and "$CONFIRM_ACTION" in script
    assert (valid_ref and valid_env and valid_destroy and valid_apply) is expect_ok
    bash_bin = shutil.which("bash")
    if bash_bin and subprocess.run([bash_bin, "-c", "true"], capture_output=True).returncode == 0:
        env = dict(os.environ)
        env.update(
            {
                "DISPATCH_REF": dispatch_ref,
                "TARGET_ENV": target_env,
                "PLAN_ONLY": plan_only,
                "DESTROY": destroy,
                "CONFIRM_ACTION": confirm_action,
            }
        )
        proc = subprocess.run([bash_bin, "-c", script], env=env, capture_output=True, text=True)
        assert (proc.returncode == 0) is expect_ok
