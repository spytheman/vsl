# Numerical Differentiation

The functions described in this chapter compute numerical derivatives by
finite differencing. An adaptive algorithm is used to find the best
choice of finite difference and to estimate the error in the derivative.

More information is available in **[the documentation of this package](https://vsl.readthedocs.io/en/latest/diff.html).**

## Usage example

```v
module diff

import vsl.math
import vsl.diff
import vsl

fn func(x f64, _ []f64) f64 {
	return math.pow(x, 1.5)
}

fn main() {
	f := vsl.Function{function: func}
	println('f(x) = x^(3/2)')
	mut expected := 1.5 * math.sqrt(2.0)
	mut result, mut abserr := diff.central(f, 2.0)
	println('x = 2.0')
	println("f'(x) = $result +/- $abserr")
	println('exact = $expected')
	expected = 0.0
	result, abserr = diff.forward(f, 0.0)
	println('x = 0.0')
	println("f'(x) = $result +/- $abserr")
	println('exact = $expected')
}
```
