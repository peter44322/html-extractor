#!/usr/bin/env node

var download = require("download-file");
var Crawler = require("crawler");
var fs = require("fs");
var shell = require("shelljs");
const normalizeUrl = require("normalize-url");
require("colors");
const helper = require("./libs/helper.js");
const entryPoint = process.argv[2];

if (!entryPoint) {
  console.log("[-] you need to provide an entry point".red);
  return;
}

if (!helper.validURL(entryPoint)) {
  console.log("[-] entry point must be a valid url".red);
}

var c = new Crawler({
  maxConnections: 10,
  // This will be called for each crawled page
  callback: function(error, res, done) {
    if (error) {
      console.log(error);
    } else {
      var $ = res.$;
      const title = $("title").text();
      let body = res.body;

      if (!fs.existsSync(title)) {
        fs.mkdirSync(title);
      }
      console.log("[+] Downloading index ".green);
      $("script,link,img,vidoe").each((_, element) => {
        const src = element.attribs.src || element.attribs.href;
        const url = normalizeUrl(entryPoint + src, {
          removeQueryParameters: [/.+/g]
        });
        if (src && !helper.validURL(src)) {
          const dir = title + "/" + src.replace(/\/[^\/]+[^\/]$/, "");
          if (!fs.existsSync(dir)) {
            shell.mkdir("-p", dir);
          }
          download(url, { directory: dir }, function(err) {
            console.log("[-] Downloading ".yellow + url.yellow);
            if (err) console.log("[-]".red + err);
            console.log("[+] Downloaded ".green + url.green);
          });
        }
      });
      fs.writeFileSync(title + "/index.html", body, "utf8");
    }
    done();
  }
});

c.queue(entryPoint);
