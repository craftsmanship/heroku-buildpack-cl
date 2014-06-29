Heroku Buildpack for Common Lisp
================================

A Buildpack that allows you to deploy Common Lisp applications on the Heroku infrastructure.

Original work by Mike Travers, mt@hyperphor.com
Secondary work by José Santos, jsmpereira@gmail.com

> Example app at http://protected-lake-6567.herokuapp.com

## Changes 
* Support for SBCL and Hunchentoot.

user-env-comlile が使えなくなっているので、 ENV_DIR に対応

* Implementation choice via env variables.
```CL_IMPL=sbcl```
or
```CL_IMPL=ccl```

* Web server choice
```CL_WEBSERVER=hunchentoot```
or
```CL_WEBSERVER=aserve```

### Notes

* To avoid trouble with SBCL source encoding use:
```heroku config:add LANG=en_US.UTF-8```

* Hunchentoot working with SBCL and CCL. AllegroServe working with CCL.
There's however an issue with AllegroServe in SBCL. acl-compat bundled in 
https://github.com/mtravers/portableaserve seems to be using some
SBCL deprecated sb-thread functions.

Hiroshi Miyaoka, craftsmanship@me.com

## Credits
* Mike Travers
* Jose Santos Martins Pereira
* Heroku and their new [Buildpack-capable stack](http://devcenter.heroku.com/articles/buildpacks)
* [QuickLisp](http://www.quicklisp.org/) library manager 
* [OpenMCL](http://trac.clozure.com/ccl) aka Clozure CL 
* [Portable AllegroServe](http://portableaserve.sourceforge.net/)
