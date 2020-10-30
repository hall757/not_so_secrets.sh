# secrets.sh

Forked version with GPG encryption removed.  I needed a simple way to generate random tokens for associations between different systems.  My use case had no need for encryption.

⚠️ **WARNING:** This code is brand new. There are no tests yet. Even I haven't started using it yet. ⚠️

  - [About](#about)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Store a secret](#store-a-secret)
    - [Retrieve a secret](#retrieve-a-secret)
    - [Forget a secret](#forget-a-secret)
    - [List all secrets](#list-all-secrets)
    - [Dump "database"](#dump-database)
  - [Environment Variables](#environment-variables)
    - [SECRETS_PATH](#secrets_path)
    - [SECRETS_GPG_PATH](#secrets_gpg_path)
    - [SECRETS_GPG_KEY](#secrets_gpg_key)
    - [SECRETS_GPG_ARGS](#secrets_gpg_args)
    - [SECRETS_LIST_FORMAT](#secrets_list_format)
    - [SECRETS_DATE_FORMAT](#secrets_date_format)
  - [Credits](#credits)
  - [Inspirations and Alternatives](#inspirations-and-alternatives)
  - [License](#license)

## About

secrets.sh is a secrets manager written in [bash](https://www.gnu.org/software/bash/); it provides a simple key-value store that is
stored in a cleartext file.

This is mostly intended for use in your dotfiles, in order to load API keys and
such into your environment, without having to store them in plain text on disk. This might be handy if you even want to store your secrets in a public
git repository, or on a server where you don't necessarily trust everyone.

It makes no effort to make its usage of GPG non-interactive; the idea is that you'll let
your GPG agent cache your passphrase so you only get prompted once per
session or so. Perhaps you might even want to use a separate GPG key dedicated
to this purpose. If you want secrets.sh to always be fully non-interactive, it's up to you to figure out how to set up a persistent agent process. The `SECRETS_GPG_ARGS` environment variable is provided to make this sort of abuse easier, but it is not a supported use case.

Keys and values may contain any arbitrary data, including spaces, newlines, Unicode, and random binary garbage. If you can figure out how to pass it to secrets.sh
as a command-line argument, then secrets.sh will do its best store it and retrieve it for you.

Care has been taken to use as few external tools as possible, so you can throw this in your dotfiles (or submodule it via [homeshick](https://github.com/andsens/homeshick)) and take it with you wherever you go. The use of `eval` when serializing and deserializing keys has been spurned in order to make shell injection attacks more difficult.

secrets.sh requires that the file the secrets are stored in is both signed and
encrypted by the same GPG key. This is to prevent people you "trust" from signing
a file with their own key and then encrypting it with your public key and
replacing your secrets with theirs.

## Installation

It's just a shell script; just copy the script somewhere you can find it later.
If anyone else actually ends up liking this I may package it in the future.

## Usage

### Store a secret
```secrets.sh set my_cool_key my_secret_value```

Outputs nothing. Returns 0 if storing the secret was successful, or non-zero otherwise.

```secrets.sh set my_cool_key```

If you leave the value off, then secrets.sh will prompt you for it. This is nice if you want to avoid something getting written to your shell history.

### Retrieve a secret
```secrets.sh get my_cool_key```

Outputs the value of the secret, or nothing if it was not found. Returns 0 if
decrypting the secrets database was successful, or non-zero otherwise.

### Forget a secret
```secrets.sh del my_cool_key```

Outputs nothing. Returns 0 if decrypting the secrets database was successful,
or non-zero otherwise.

Note that this just removes the secret from the secrets database; it doesn't take any special pains to scrub the old version of the secrets file off of the disk or out of any repository that it may be stored in. If you really need to kill something with fire, you'll need to bring your own fire.

### List all secrets
```secrets.sh list```

Outputs a sorted list of keys and the date the were last modified.
The output of the `list` command can be customized -- [see below](#secrets_list_format) for details.

### Dump "database"
```secrets.sh dump```

This is mainly intended for debugging, or if you need to do something cool
enough that you need access to the raw data. The decrypted form of the database
is three shell-quoted URL-encoded strings separated by spaces and followed by a newline
(e.g, `printf "%q %q %q" $key $date $value`). The first string is the key,
the second string is the time the key was set in seconds-since-the-epoch, and
the third string is the value. You can process this output line-by-line by
doing something like `while read key date value ; do ... ; done`.

## Environment Variables

### `SECRETS_PATH`

The path of the secrets database. Defaults to `$HOME/.secrets`.

### `SECRETS_GPG_PATH`

The path to the `gpg` program to use. Defaults to `gpg2` if available, and `gpg` otherwise.

### `SECRETS_GPG_ARGS`

Extra arguments to pass to `gpg`. No default value.

### `SECRETS_GPG_KEY`

The ID of the key to use when encrypting/signing/decrypting/verifying the secrets database. If unspecified, uses your default GPG key.

### `SECRETS_LIST_FORMAT`

The  [`printf`](http://wiki.bash-hackers.org/commands/builtin/printf) format used for the [`list`](#list-all-secrets) command. The first field is the key and the second field is the formatted date that the key was last modified. Defaults to `%-$((COLUMNS - 26))s | %s`.

### `SECRETS_DATE_FORMAT`

The [`date`](http://man7.org/linux/man-pages/man1/date.1.html) format used for formatting the date displayed by the [`list`](#list-all-secrets) command. Defaults to `%F %I:%M%p %Z`.

## Credits

  - `urlencode` by [Brian K. White](https://github.com/aljex)
  - `urldecode` by [Chris Down](https://github.com/cdown)

## Inspirations and Alternatives

As stated above, secrets.sh is mainly intended for securely storing values that you want your dotfiles to inject into your environment. If you're looking for something more like a full-featured password manager for your shell, check out the following alternatives:

  - [pass](https://www.passwordstore.org/)
  - [passbox](https://github.com/RobBollons/passbox)
  - [pony](https://github.com/jessfraz/pony)
  - [pwd.sh](https://github.com/drduh/pwd.sh)

If you're specifically interested in storing secrets in Git repositories, you might want to give these a try:

  - [git-crypt](https://www.agwa.name/projects/git-crypt/)
  - [git-secret](http://git-secret.io/)

## License

Copyright (c) 2018 Jordan Webb - [MIT License](https://github.com/jordemort/secrets.sh/blob/master/LICENSE)
