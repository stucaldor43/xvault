function createXHRRequest(method, url, cb, options) {
    var req = new XMLHttpRequest();

    req.open(method.toUpperCase(), url);
    if(options && options.header) {
        req.setRequestHeader(options.header.name, options.header.value)
    }
    req.onreadystatechange = cb;
    return req;
};