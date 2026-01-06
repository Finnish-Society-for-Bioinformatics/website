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
