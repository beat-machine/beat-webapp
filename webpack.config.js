const PrettierPlugin = require("prettier-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");
const webpack = require("webpack");

module.exports = {
    module: {
        rules: [{
            test: /\.html$/,
            exclude: /node_modules/,
            loader: 'file-loader?name=[name].[ext]'
        }, {
            test: /\.elm$/,
            exclude: [/elm-stuff/, /node_modules/],
            use: {
                loader: 'elm-webpack-loader',
                options: {}
            }
        }, {
            test:  /\.css$/i,
            use: ['style-loader', 'css-loader'],
        }]
    },

    devServer: {
        inline: true,
        stats: 'errors-only'
    },

    plugins: [
        new PrettierPlugin(),
        new webpack.EnvironmentPlugin(["BASE_URL"]),
        new CopyWebpackPlugin([
            { from: 'public' }
        ])
    ]
};
