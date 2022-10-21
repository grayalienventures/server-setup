const path = require("path");
const webpack = require('webpack');
// const HtmlWebpackPlugin = require('html-webpack-plugin')
const dotenv = require('dotenv');
dotenv.config()
var environment = process.env.NODE_ENV || 'development';
module.exports = () => {
  const env = dotenv.config().parsed;

  const envKeys = Object.keys(env).reduce((prev, next) => {
    prev[`process.env.${next}`] = JSON.stringify(env[next]);
    return prev;
  }, {});
  return {
    entry: './src/index.js',
    mode: environment,
    output: {
      path: path.join(__dirname, "/dist"),
      filename: "./bundle.js"
    },
    plugins: [
      // new HtmlWebpackPlugin({
      //    title: 'My App',
      //    template:  path.join(__dirname, "/src/assets/template.html")
      // }),
      new webpack.DefinePlugin(envKeys)
    ],

    module: {
      rules: [
        {
          test: /\.js$/,
          exclude: /(node_modules|bower_components)/,
          use: [{
            loader: 'babel-loader',
            options: {
              presets: ["@babel/preset-env", "@babel/preset-react"]
            }
          }]
        },
        {
          test: /\.css$/,
          use: ["style-loader", "css-loader"]
        },
        {
          test: /\.(jpe?g|png|gif|woff|woff2|eot|ttf|svg)(\?[a-z0-9=.]+)?$/,
          loader: 'url-loader?limit=100000'
        }

      ],

    }
  }
};
