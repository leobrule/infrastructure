# Bundled Terraform ruleset (no plugin download needed).
# Optional later: add the Google ruleset plugin
# (https://github.com/terraform-linters/tflint-ruleset-google) with a pinned version.
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
