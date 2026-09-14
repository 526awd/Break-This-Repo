# PROVENANCE — `csharp/pulled/nodatime`

This directory contains **verbatim source code from another repository**, imported deliberately to
raise the C# share of this repository's language statistics, which `AGENTS.md` now requires to
exceed the Rust share. The import is declared here in full because an undeclared vendored copy is
indistinguishable from plagiarism, and this is not that.

| | |
| --- | --- |
| Upstream | <https://github.com/nodatime/nodatime> |
| Upstream commit | `7aa2e026eb6c129fd3411d9a19223d0a2931fd50` (shallow clone of the default branch at import time) |
| Imported subtree | `src/NodaTime/` → `csharp/pulled/nodatime/` |
| Files imported | 182 `.cs` files + `TimeZones/Cldr/` resources + `TimeZones/Tzdb.nzd` |
| Licence | Apache-2.0 — see `UPSTREAM-LICENSE.txt` (copied unmodified from the upstream root) |
| Bytes of C# | 1 780 492 |
| Modifications to the imported source | **none.** Not one character of the upstream `.cs` files was edited. |

## What *was* changed, and why

The upstream build file was removed and replaced by `NodaTime.csproj` in this directory, because the
upstream project is a *packaging* project and this is a *vendored copy*:

| Upstream does | This copy does | Why |
| --- | --- | --- |
| `TargetFrameworks: netstandard2.0;net8.0` | net8.0 only (from `../Directory.Build.props`) | only one consumer, one TFM |
| `SignAssembly=true` + `NodaTime Release.snk` | `SignAssembly=false` | no release key, and a strong name nobody verifies |
| `PackageReference Microsoft.CodeAnalysis.NetAnalyzers` | no package references at all | keeps the whole solution offline-buildable |
| `PackageValidation`, `ApiCompat`, `IsPackable` | off | this copy is not a package and makes no compatibility promise |
| `GenerateDocumentationFile=true` | `false` | keeps the build output quiet |

**Consequences, stated plainly:** this copy is not published as a NuGet package, does not carry
upstream's strong name or upstream's public API compatibility promise, and receives no upstream
fixes. It is a pinned snapshot, on purpose.

## How it is used (it is not dead weight)

`csharp/DreamSeeker.Cli` references `NodaTime.csproj` and calls into it on every run: it takes an
`Instant` from `SystemClock`, adds a `Duration`, and projects it into a `LocalDate`. The line

```text
Instant now=2026-09-14T11:02:54Z  LocalDate(UTC)=Monday, 14 September 2026  Instant+Duration=2026-09-14T11:02:55Z
```

is produced by that library, compiled from the sources in this directory by this solution. The
point of the import is exactly that it *compiles and runs*, so it is wired into the build and
exercised by `DreamSeeker.Cli` instead of sitting in a folder being counted.

## Language statistics note

`.gitattributes` in the repository root carries `csharp/pulled/** linguist-vendored=false`. GitHub's
linguist excludes paths that look vendored — `vendor/`, `third_party/`, `deps/`, `external/` — from
the language bar. This path deliberately does not look vendored, and the attribute makes the intent
unambiguous: **this code is counted on purpose, and it is attributed here on purpose.**
