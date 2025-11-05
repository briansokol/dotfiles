#!/bin/zsh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

updateNpmOutdated () {
    echo "\nVerifying cache"
    npm cache verify

    echo "\nUpdating npm"
    nvm install-latest-npm

    echo "\nScanning for outdated packages..."
    for package in $(ncu -g --jsonUpgraded | jq 'to_entries' | jq '.[] | @text "\(.key)@\(.value)"')
    do
        stripped="$(echo $package | cut -d \" -f 2)"
        if [[ "$stripped" = "npm@"* ]]; then
    		continue
		fi
        echo "\nUpgrading -> $stripped"
        npm -g install --quiet "$stripped"
    done

    echo "\nDone"
}

echo "\nUpdating Zinit..."
zinit self-update

echo "\nUpdating Zinit Plugins..."
zinit update --parallel

echo "\nUpdating Homebrew dependency formulas..."
brew update
brew upgrade
brew upgrade --cask
echo "\nCleaning up..."
brew cleanup

echo "\nUpdating npm dependencies..."

echo "$(nvm list)" | while IFS= read -r line
do
    version="$(echo "${line}" | tr -d '[:space:]' | sed 's/->//g' | sed -E "s/"$'\E'"\[([0-9]{1,2}(;[0-9]{1,2})*)?m//g")"
    version="${version}"

    if [ "$version" = "" ]
    then
        continue
    fi

    if [[ "$version" != "v"* ]]; then
    	continue
	fi

    echo "\nUpdating node $version"
    nvm use "$version"
    updateNpmOutdated
done

echo "\nAll dependencies up-to-date."

