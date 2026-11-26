# How to build and preview the website

_Note_: The following instructions have been tested on desktop Linux. They
should work on Windows Subsystem for Linux and macOS.

1. Install [Quarto](https://docs.posit.co/resources/install-quarto.html) and
   [R](https://www.r-project.org/).
   1. [Install](https://git-scm.com/downloads/linux) git.
   2. [Generate](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
      and
      [add](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
      an SSH key to your GitHub account.
   3. Clone this repo to your machine: `git clone
git@github.com:Finnish-Society-for-Bioinformatics/website.git`
   4. Enter the repository `cd website`.
   5. When the website code updates, you only need to run `git pull` from the
      repository to receive new updates.
   6. Run `quarto preview`. The website should open in browser.
   7. If needed, install required packages:
      - Enter R console with `R` command.
      - Run `install.packages(c("knitr", "rmarkdown", "yaml"))`.
