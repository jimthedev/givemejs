#!/bin/bash

# gimme.sh organization/testrepo << Creates it under organizatiions github
#     - OR -
# gimme.sh testrepo    << Creates it under my github 

set -e

# Get the path of the current script, regardless of symlinks
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Input, should be the repo to create 
#IN="testrepo"
#IN="jimthedev/testrepo"
IN=$1

# Split the input string into an array
IFS='/' read -r -a REPOPARTS <<< "$IN"

# Get the number of parts after split
INLEN=${#REPOPARTS[@]}

# Assume that if theres only one part, there is no organization
if [ -z "${REPOPARTS[1]}" ]; then
  ORGNAME=
  REPONAME=${REPOPARTS[0]}
else
  ORGNAME=${REPOPARTS[0]}
  REPONAME=${REPOPARTS[1]}
fi

# Make sure we actually got a repo name/
if [ -z $REPONAME  ]; then
  echo "Could not find a repo name in the arguments provided."
  exit 1;
else
  echo "Organization provided: $ORGNAME"
  echo "Repo provided: $REPONAME"
  REPOPATH=$REPONAME
fi

if [ "$(ls -A $REPOPATH)" ]; then
  echo "Well this is awkward. $REPOPATH exists and isn't empty. Aborting."
  exit 1;
fi

hash git 2>/dev/null || { echo >&2 "I require git but it's not installed in your PATH. Pleast install git or add it to your path before continuing.  Aborting."; exit 1; }
hash hub 2>/dev/null || { echo >&2 "I require hub but it's not installed. Run brew install hub or download it from https://hub.github.com/.  Aborting."; exit 1; }
hash node 2>/dev/null || { echo >&2 "I require node.js but it's not installed in your PATH. Run brew install hub or download it from https://nodejs.org/.  Aborting."; exit 1; }
hash npm 2>/dev/null || { echo >&2 "I require npm but it's not installed in your PATH. Please install npm or add it to your path before continuing.  Aborting."; exit 1; }
hash curl 2>/dev/null || { echo >&2 "I require curl but it's not installed in your PATH. Please install curl in order to continue. Aborting"; exit 1; }

# Create a folder to hold our 
if [ ! -d "$REPOPATH" ]; then
	mkdir $REPOPATH
fi

cd $REPOPATH

echo "Initializing git repo"
if [ ! -d ".git" ]; then
  git init
fi

echo "Initializing NPM package"
if [ ! -f "package.json" ]; then
  npm init --yes
fi

# Node, we use babel5 here because babel 6 doesn't support having 
# babel 5 projects nested in the same folder tree yet
# https://phabricator.babeljs.io/T3015#66463
echo "Installing initial"
npm install --save-dev --save-exact \
  babel-core@5 \
  babel-loader@5 \
  commitizen  \
  greenkeeper \
  html-webpack-plugin \
  semantic-release \
  webpack \
  webpack-dev-server
  
# Install some things we need for this script but don't save to package.json
npm install \
  lodash \
  detect-indent \
  semantic-release-cli

# Set up commitizen
./node_modules/commitizen/bin/commitizen init cz-conventional-changelog --save-dev --save-exact 

# Get the node.js gitignore file
curl -o ./.gitignore https://raw.githubusercontent.com/github/gitignore/master/Node.gitignore
cat <<EOT >> .gitignore
dist
EOT

# Write a jsconfig.json for Visual Studio Code
cat <<EOF > jsconfig.json
{
    "compilerOptions": {
        "target": "ES6",
        "module": "commonjs",
        "experimentalDecorators" : true
    }
}
EOF

# Modify the package.json to add our scripts and config
cat <<EOF > .gimme.js
var fs = require('fs');
var _ = require('lodash');
var detectIndent = require('detect-indent');

var toMerge = {
  version: '0.0.0-semantically-released',
  repository: {
    type: 'git',
    url: 'https://github.com//$REPONAME.git'
  },
  scripts: {
    commit: 'git-cz',
    serve: 'webpack-dev-server',
    build: 'webpack',
    
  }
};

var packageJsonPath = 'package.json';
var packageJsonString = fs.readFileSync(packageJsonPath, 'utf-8');
// tries to detect the indentation and falls back to a default if it can't
var indent = detectIndent(packageJsonString).indent || '  ';
var packageJsonContent = JSON.parse(packageJsonString);
var newPackageJsonContent = _.merge(packageJsonContent, toMerge);
fs.writeFileSync(packageJsonPath, JSON.stringify(newPackageJsonContent, null, indent));
EOF

node .gimme.js
rm .gimme.js

# Check if we are logged in
if echo "$(./node_modules/.bin/greenkeeper whoami 2>&1)" | grep -q "Login required"; then
  ./node_modules/.bin/greenkeeper login
fi

echo "Creating github repo."
hub create

# Get the url of the created repo
REPOSSHURL=$(git config --get remote.origin.url)
echo $REPOSSHURL
REPOHTTPSURL=${REPOSSHURL/git@github.com:/https://github.com/}
echo $REPOHTTPSURL
# Modify the package.json to add the git url

cat <<EOF > .gimme.js
var fs = require('fs');
var _ = require('lodash');
var detectIndent = require('detect-indent');

var toMerge = {
  repository: {
    type: 'git',
    url: '$REPOHTTPSURL'
  }
};

var packageJsonPath = 'package.json';
var packageJsonString = fs.readFileSync(packageJsonPath, 'utf-8');
// tries to detect the indentation and falls back to a default if it can't
var indent = detectIndent(packageJsonString).indent || '  ';
var packageJsonContent = JSON.parse(packageJsonString);
var newPackageJsonContent = _.merge(packageJsonContent, toMerge);
fs.writeFileSync(packageJsonPath, JSON.stringify(newPackageJsonContent, null, indent));
EOF

node .gimme.js
rm .gimme.js

echo "Enabling greenkeeper"
./node_modules/.bin/greenkeeper enable

echo "Setting up semantic release"
node ./node_modules/semantic-release-cli/bin/semantic-release.js setup --retain-version

mkdir src
touch src/index.js

mkdir other
cat <<EOF > other/index.template.html
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8"/>
    <title>{%= o.htmlWebpackPlugin.options.title %}</title>
  </head>
  <body id="app">
  </body>
</html>
EOF

cat <<EOF > webpack.config.js
var path = require('path');
var HtmlWebpackPlugin = require('html-webpack-plugin');
module.exports = {
  entry: "./src/index.js",
  output: {
    path: path.join(__dirname, 'dist'),
    filename: "index.js",
    hash:true
  },
  module: {
    loaders: [
      { test: /\.css$/, exclude: /node_modules/, loader: "style!css" },
      { test: /\.js$/, exclude: /node_modules/, loader: "babel-loader"}
    ]
  },
  plugins: [
    new HtmlWebpackPlugin({
      title: 'App',
      filename: 'index.html', // output filename
      template: 'other/index.template.html', // Load a custom template 
      inject: 'body' // Inject all scripts into the body 
    })
  ]
};
EOF

exec $DIR/adapters/$2 $REPOPATH