# trevoke.github.io-source

Source repo for `blog.trevoke.net`, a Hugo site written in org-mode. Built HTML is
published from a separate repo via a git submodule — this repo never publishes
directly.

## Architecture

- **This repo** (`trevoke.github.io-source`) — org-mode content, Hugo config, themes.
  Nothing here is served directly.
- **`public/`** — a git submodule pointing at `git@github.com:Trevoke/trevoke.github.io.git`,
  the actual GitHub Pages repo (served from its `master` branch). `hugo` builds into
  this directory; committing/pushing inside `public/` is what publishes the site.
- **`themes/`** — five theme submodules (`hugo-tufte`, `kiss`, `binario`, `even`,
  `hello-friend-ng`). Only one is active at a time, set by `theme = "..."` in
  `config.toml` (currently `hugo-tufte`). The others are just parked there — don't
  assume an unfamiliar diff in `themes/` matters unless it's the active theme.
- Posts live in `content/post/*.org`. Hugo has native org-mode support (via go-org),
  so no preprocessing step converts org to markdown.

## Writing a post

Org front matter convention (see any existing post, or `archetypes/maybe-default.org`):

```org
#+TITLE: Post Title Here
#+DATE: 2026-07-15T21:12:27-04:00
#+DRAFT: nil
#+CATEGORIES[]: category-one category-two
#+TAGS[]: tag-one tag-two tag-three
#+DESCRIPTION: One-sentence summary for feeds/meta.

* First heading
Body content...
```

To scaffold one with correct front matter (the default archetype is markdown, so pass
`-k` explicitly):

```sh
hugo new --kind maybe-default content/post/my-new-post.org
```

Otherwise just copy an existing `.org` file's front matter and edit it.

## Previewing locally

```sh
hugo server -t hugo-tufte -D   # -D includes drafts
```

Serves at `localhost:1313`. Do this before deploying to catch build errors or broken
front matter — `deploy.sh` does not stop to let you review the render.

## Deploying (`./deploy.sh ["commit message"]`)

This is the whole publish flow. Read it before running it, since it commits and
pushes to **two remotes** with no confirmation prompt:

1. `hugo -t hugo-tufte` — builds the site into `public/`.
2. `cd public && git add -A && git commit -m "<msg or 'rebuilding site <date>'>"`
3. `git push origin master` — pushes the **live site** to the pages repo.
4. `cd .. && git add -A && git commit -am "update generated site submodule"`
5. `git push origin master` — pushes source changes + the submodule pointer bump.

Notes:
- Step 3 happens **before** step 5 — if you interrupt after step 3, the live site is
  already updated but the source repo hasn't recorded the new submodule commit yet.
  Re-running `deploy.sh` (or just doing steps 4–5 by hand) fixes that.
- The default commit message is used for *both* commits unless you pass one:
  `./deploy.sh "post: my new post title"`.
- If you only want to preview the build output without publishing, run `hugo -t
  hugo-tufte` and inspect `public/` — just don't commit/push inside it.

## Assessing current state / cleaning up

Before writing new content or deploying, check both the source repo and the `public`
submodule — they drift independently:

```sh
git status                              # source repo: new/changed posts, config, etc.
git -C public status                    # is the built site actually committed/pushed?
git submodule status                    # one line per submodule; leading '-' = not
                                         # initialized, leading '+' = checked-out commit
                                         # differs from what's recorded here
```

Things worth checking specifically:

- **Untracked `.org` files in `content/post/`** — new posts that were written but
  never built/deployed. `deploy.sh` will pick them up automatically on the next run.
- **`public/` showing a large uncommitted diff** — usually means `hugo` was run
  locally (e.g. via `hugo server`, or a partial `deploy.sh` run) but the result was
  never committed/pushed from inside `public/`. Check `git -C public status`; if it
  looks like a legitimate rebuild, finish the deploy (steps 2–3 above) rather than
  discarding it.
- **`themes/hello-friend-ng` (or any non-active theme) showing local changes /
  detached HEAD** — it's not in use per `config.toml`, so this is dead weight, not a
  blocker. Don't try to "fix" it by resetting unless you're intentionally working on
  that theme; it's safe to leave alone.
- **`themes/hugo-tufte` showing `-` in `git submodule status`** — means the
  submodule isn't properly registered even though files exist on disk (likely from a
  manual clone at some point). This is the *active* theme, so if `hugo` builds fine,
  leave it; if you need to fix the registration cleanly:
  `git submodule update --init themes/hugo-tufte`.
- **`.hugo_build.lock` and `resources/` are tracked in git** — these are Hugo build
  artifacts and probably shouldn't be committed, but that's a pre-existing repo
  quirk, not something to "fix" as a side effect of an unrelated change. Only touch
  it if the user asks.

General rule: never run destructive git operations (`reset --hard`, `clean -f`,
discarding submodule changes) inside `public/` or `themes/` without confirming first
— `public/`'s history *is* the live site's deploy history.
