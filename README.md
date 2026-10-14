# How to build and preview the website

_Note_: The following instructions have been tested on desktop Linux. They
should work on Windows Subsystem for Linux and macOS.

1. Install [Quarto](https://docs.posit.co/resources/install-quarto.html) and
   [R](https://www.r-project.org/). Now you have two options below.
2. If you want ease-of-use for the future website updates and know git:
   1. [Install](https://git-scm.com/downloads/linux) git.
   2. [Generate](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
      and
      [add](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
      an SSH key to your GitHub account.
   3. Clone this repo to your machine: `git clone
git@github.com:Finnish-Society-for-Bioinformatics/website.git`
   4. Enter the repository `cd website`.
   5. The bleeding-edge website version is in `devel` branch, so switch to it:
      `git checkout devel`.
   6. When the website code updates, you only need to run `git pull` from the
      repository to receive new updates.
3. If you want to run the _current_ version of the website with slighly more
   complicated updates in the future: 1. Select `devel` branch or use [direct
   link](https://github.com/Finnish-Society-for-Bioinformatics/website/tree/devel#).
4. Click "Code" and "Download ZIP". 3. Unzip the downloaded archive. On Linux,
   use `unzip <archive_name.zip>`. 4. Enter the unzipped directory.
5. Run `quarto preview`. The website should open in browser.
6. If the command says that `rmarkdown` and/or `knitr` are not found, install
   them:
   - Enter R console with `R` command.
   - Run `install.packages(c("knitr", "rmarkdown"))`.
   - Exit the R console and run `quarto preview`.

# How to Add New Events?

Adding/modifying events on the Events pages is a straightforward but a bit
delicate process.

If you need to **modify** an event, just modify the _text_, not the code.

If you need to **add** an event, scroll down until `<!-- Use the second event
from here as template to keep the structure -->`. If you insert this event,
it's going it be the Hackathon even.

Next, scroll until `<!-- Use the first  event from here as template to keep the
structure -->`. If you insert the event under this comment, it's going to be
BioBeer.

Just keep on inserting the "first" event after the "second" event to keep the
structure. The "first" event refers to the event with the image to the left,
and the "second" even refers to the event with the image to the right.

# Bioconductor Community Map

The map on the [Bioconductor page](pages/communities/bioconductor.qmd) shows
people from `data/bioconductor_members.yaml`. People add, modify, and remove
their entries by opening an issue from one of the `bioc-map-*` issue
templates:

1. The [Bioconductor map workflow](.github/workflows/bioc-map.yml) checks the
   issue (the city exists, GitHub user exists, valid links, etc.;
   the map location is looked up from the city and country), posts a
   report as a comment, and labels the issue `bioc-map: valid` or
   `bioc-map: needs changes`. Editing the issue runs the check again.
2. A maintainer reviews the request. For modifications and removals, the
   report tells whether the issue author is the person in the entry.
3. The maintainer adds the `approved` label. The workflow opens a pull request
   that updates the data file and closes the issue when merged.

One-time setup:

- The labels used by the templates are created by the
  [Labels workflow](.github/workflows/labels.yml). It runs automatically when
  that file changes on `main`; run it manually from the Actions tab in a new
  fork. If an issue was opened before the labels existed, add the labels to
  the issue by hand and the check runs.
- Enable _Settings > Actions > General > Allow GitHub Actions to create and
  approve pull requests_.

Note that pull requests opened by GitHub Actions do not trigger other
workflows. The website is published when the pull request is merged.

# Job Advertisements

The [Jobs page](pages/jobs.qmd) lists the jobs in `data/jobs.yaml`. Anyone can
submit a job by opening an issue from the `job-ad` issue template:

1. The [job advertisement workflow](.github/workflows/job-ads.yml) checks the
   issue (required fields, valid link, expiry date in the future), posts a
   report as a comment, and labels the issue `job-ad: valid` or
   `job-ad: needs changes`. Editing the issue runs the check again.
2. A maintainer reviews the advertisement and adds the `approved` label. The
   workflow opens a pull request that adds the job to the data file and closes
   the issue when merged.

Expired jobs are hidden in the browser (see `pages/_jobs.html`), so the website
does not need to be rendered again when a job expires. Expired jobs are also
left out whenever the website is rendered. To remove a job early, for example
when the position has been filled, open an issue from the `job-ad-remove`
template. It is checked and approved the same way; the report tells whether
the issue author is the person who submitted the advertisement.

The labels and the GitHub Actions setting are shared with the Bioconductor
map (see above).
