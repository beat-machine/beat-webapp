const webpack = require("webpack");
const childProcess = require("child_process");

let commitInfo = childProcess
  .execSync('git show -s --format="%s"')
  .toString()
  .trim();
let commitHash = childProcess
  .execSync('git show -s --format="%h"')
  .toString()
  .trim();
let commitTimestamp = childProcess
  .execSync('git show -s --format="%at"')
  .toString()
  .trim();

module.exports = {
  configureWebpack: {
    plugins: [
      new webpack.DefinePlugin({
        COMMIT_INFO: `"${commitInfo}"`,
        COMMIT_HASH: `"${commitHash}"`,
        COMMIT_TIMESTAMP: `"${commitTimestamp}"`
      }),
      new webpack.EnvironmentPlugin({
        BEATAPP_BASE_URL: "https://beatfunc-zz5hrgpina-uc.a.run.app",
        BEATAPP_VERSION: "develop"
      })
    ]
  },
  css: {
    loaderOptions: {
      sass: {
        data: '@import "@/scss/global.scss";'
      }
    }
  }
};
