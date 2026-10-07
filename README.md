# macula-codex

Macula's public PDFs, each signed by the CI that built it, so anyone can check that our CI made it and that nobody
changed it since.

Download them from **[Releases](https://github.com/macula-io/macula-codex/releases)**. Each release is dated and
carries every PDF next to a `.sigstore.json` bundle: its signature, the certificate of the CI workflow that signed it,
and the record of that signature in Sigstore's public transparency log.

## What is published

| Release name contains | Document | Signed by (workflow identity) |
|---|---|---|
| `readme-pdf` | `README.pdf`: what Macula is, why it matters, what is built | `https://github.com/macula-io/macula-ecosystem/.github/workflows/readme-pdf.yml@refs/heads/main` |
| `register-pdf` | `SECURITY_FEATURES.pdf`: the public edition of Macula's security register, and `register-stamp.json`, the register commit and the live check it was built from | `https://github.com/macula-io/macula-architecture/.github/workflows/security-register-export.yml@refs/heads/main` |

The source repositories are private; the identity still names exactly which workflow, on which branch, signed the file.

## Verify a PDF yourself

You need [cosign](https://docs.sigstore.dev/cosign/system_config/installation/) version 3. Download the PDF and its
bundle from the same release, then run, for `README.pdf`:

```sh
cosign verify-blob \
  --bundle README.pdf.sigstore.json \
  --certificate-identity https://github.com/macula-io/macula-ecosystem/.github/workflows/readme-pdf.yml@refs/heads/main \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  README.pdf
```

and for `SECURITY_FEATURES.pdf` (and `register-stamp.json`, the same way):

```sh
cosign verify-blob \
  --bundle SECURITY_FEATURES.pdf.sigstore.json \
  --certificate-identity https://github.com/macula-io/macula-architecture/.github/workflows/security-register-export.yml@refs/heads/main \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  SECURITY_FEATURES.pdf
```

`Verified OK` means: this exact file was signed by that workflow, running on the `main` branch of that repository in
GitHub Actions, and the signature is recorded in the public transparency log. Anything else, including a different
identity, means do not trust the file.

Always pass the full identity exactly as above, never a pattern: a pattern can match a workflow we did not write.

## How a PDF gets here

1. A source repository's CI builds the PDF on a push to its `main`, signs it with
   [cosign keyless signing](https://docs.sigstore.dev/cosign/signing/overview/) (the workflow's own GitHub identity, no
   long-lived key), and pushes the PDF and its bundle to a delivery branch here (`readme-pdf` or `register-pdf`).
2. [`publish`](.github/workflows/publish.yml) verifies every delivered file against that branch's one identity
   ([`scripts/identity.sh`](scripts/identity.sh), [`scripts/verify_delivery.sh`](scripts/verify_delivery.sh)), refuses
   anything else, and only then publishes a dated release.
3. [`audit`](.github/workflows/audit.yml) re-verifies every release every night, from `main`, and opens an issue for any
   file that does not verify.

The check that counts is yours: the steps above keep bad files out, but a file is trustworthy because it verifies on
your machine, not because it is listed here.

## License

Apache 2.0. See [LICENSE](LICENSE).
