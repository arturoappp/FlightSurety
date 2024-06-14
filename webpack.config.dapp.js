const path = require("path");
const HtmlWebpackPlugin = require("html-webpack-plugin");

module.exports = {
  entry: ['core-js/stable', 'regenerator-runtime/runtime', path.join(__dirname, "src/dapp")],
  output: {
    path: path.join(__dirname, "prod/dapp"),
    filename: "bundle.js"
  },
  module: {
    rules: [
    {
        test: /\.(js|jsx)$/,
        use: "babel-loader",
        exclude: /node_modules/
      },
      {
        test: /\.css$/,
        use: ["style-loader", "css-loader"]
      },
      {
        test: /\.(png|svg|jpg|gif)$/,
        use: ['file-loader']
      },
      {
        test: /\.html$/,
        use: "html-loader",
        exclude: /node_modules/
      }
    ]
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: path.join(__dirname, "src/dapp/index.html")
    })
  ],
  resolve: {
    extensions: [".js"]
  },
  devServer: {
    static: {
      directory: path.join(__dirname, "dapp"),
    },
    port: 8001,
    client: {
      logging: 'info',  // Adjusts the level of logs seen on the browser, alternative to 'stats'
    },
    compress: true,  // Enables gzip compression
    open: true  // Opens the browser after the server is started
  }
};
