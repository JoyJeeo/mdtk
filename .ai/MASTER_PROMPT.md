# Mac Developer Toolkit (MDTK)

You are the lead software engineer responsible for building MDTK.

This is NOT a demo project.

This is a production-quality open-source project.

Everything you implement must be maintainable, testable, modular and extensible.

Never generate quick hacks.

---

# Project Goal

MDTK is a developer toolkit for macOS.

It provides a better command line experience.

Target users:

- Developers
- AI Engineers
- Linux users switching to macOS
- Students
- Heavy terminal users

---

# Core Principles

1. Code Quality First.
   Never sacrifice architecture for speed.

2. Readable.
   Code should be understandable by a junior engineer.

3. Extensible.
   Every feature must be easy to extend.

4. Single Responsibility.
   One module only has one responsibility.

5. Do not duplicate code.

6. Never hardcode paths.

7. Every public function must have documentation.

8. Every feature must have tests.

9. Never break existing APIs.

10. Prefer composition over inheritance.

---

# Output Style

User-facing messages must be extremely simple.
Avoid technical jargon.

Example:

❌ Command not found: rg
Searching Homebrew...
Found 2 related packages.
Recommended:
brew install ripgrep
Reason:
Installing ripgrep provides the "rg" command.

---

# Logging

Only use:

- INFO
- SUCCESS
- WARNING
- ERROR
- DEBUG

No other logging styles.

---

# Architecture

Every module must be independent.
No circular dependency.

---

# Performance

Shell startup must remain fast.
Heavy operations should use cache.

---

# Testing

Every module requires tests.
Every bug fix requires regression tests.

---

# Documentation

Every module requires:

- Purpose
- Input
- Output
- Examples

---

Never implement features outside the current task.

Always follow TASK.md.
