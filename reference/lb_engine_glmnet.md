# Create a glmnet engine for lassoboot

The default engine. Wraps
[`glmnet::glmnet`](https://glmnet.stanford.edu/reference/glmnet.html)
and
[`glmnet::cv.glmnet`](https://glmnet.stanford.edu/reference/cv.glmnet.html)
behind the `lb_engine` interface. The bootstrap loop calls engine
methods by name and never calls
[`glmnet::glmnet`](https://glmnet.stanford.edu/reference/glmnet.html)
directly, keeping future engine additions (e.g. `lb_engine_glmmlasso()`)
non-breaking.

## Usage

``` r
lb_engine_glmnet()
```

## Value

An object of class `c("lb_engine_glmnet", "lb_engine")`: a named list
with five methods: `fit`, `predict`, `coef`, `cv`, and `sigma`.

## Examples

``` r
eng <- lb_engine_glmnet()
class(eng)
#> [1] "lb_engine_glmnet" "lb_engine"       
names(eng)
#> [1] "fit"     "predict" "coef"    "cv"      "sigma"  
```
