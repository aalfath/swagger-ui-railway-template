// Added by the Railway template: lists the OpenAPI files stored in /specs/
// (the Railway volume) so they show up in Swagger UI's "Select a definition" menu.
window.__railwaySpecUrls = function () {
  return fetch("/specs/", { cache: "no-store" })
    .then(function (r) { return r.ok ? r.json() : []; })
    .then(function (list) {
      var urls = list
        .filter(function (f) { return f.type === "file" && /\.(json|ya?ml)$/i.test(f.name); })
        .map(function (f) { return f.name; })
        .sort()
        .map(function (n) { return { url: "/specs/" + encodeURIComponent(n), name: n }; });
      return urls.length ? urls : undefined;
    })
    .catch(function () { return undefined; });
};
