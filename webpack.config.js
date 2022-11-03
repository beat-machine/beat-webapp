const CopyPlugin = require("copy-webpack-plugin");
const webpack = require("webpack");

module.exports = (env, argv) => ({
    module: {
        rules: [{
            test: /\.html$/,
            exclude: [/elm-stuff/, /node_modules/],
            use: {
                loader: 'file-loader',
                options: {
                    name: '[name].[ext]'
                },
            },
        }, {
            test: /\.elm$/,
            exclude: [/elm-stuff/, /node_modules/],
            use: {
                loader: 'elm-webpack-loader',
                options: {
                    optimize: argv.mode === 'production'
                }
            }
        }, {
            test: /\.css$/i,
            use: ['style-loader', 'css-loader'],
        }]
    },

    plugins: [
        new webpack.EnvironmentPlugin({
            BASE_URL: 'http://localhost:8000',
            VERSION: 'dev',
        }),
        new CopyPlugin({
            patterns: [
                'assets/'
            ]
        })
    ],
});
