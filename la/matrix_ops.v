// Copyright (c) 2019-2020 Ulises Jeremias Cornejo Fandos. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module la

import vsl.errno
import vsl.blas
import vsl.math

// matrix_inv_small computes the inverse of small matrices of size 1x1, 2x2, or 3x3.
// It also returns the determinant.
// Input:
// a   -- the matrix
// tol -- tolerance to assume zero determinant
// Output:
// ai  -- the inverse matrix
// det -- determinant of a
pub fn matrix_inv_small(mut ai Matrix, mut a Matrix, tol f64) f64 {
	mut det := 0.0
	if a.m == 1 && a.n == 1 {
		det = a.get(0, 0)
		if math.abs(det) < tol {
			errno.vsl_panic('inverse of ($a.m x $a.n) matrix failed with zero determinant: |det(a)| = $det < $tol',
				.efailed)
		}
		ai.set(0, 0, 1.0 / det)
	} else if a.m == 2 && a.n == 2 {
		det = a.get(0, 0) * a.get(1, 1) - (a.get(0, 1)) * a.get(1, 0)
		if math.abs(det) < tol {
			errno.vsl_panic('inverse of ($a.m x $a.n) matrix failed with zero determinant: |det(a)| = $det < $tol',
				.efailed)
		}
		ai.set(0, 0, a.get(1, 1) / det)
		ai.set(0, 1, -(a.get(0, 1)) / det)
		ai.set(1, 0, - (a.get(1, 0)) / det)
		ai.set(1, 1, a.get(0, 0) / det)
	} else if a.m == 3 && a.n == 3 {
		det = a.get(0, 0) * (a.get(1, 1) * a.get(2, 2) -
			a.get(1, 2) * a.get(2, 1)) - (a.get(0, 1)) *
			(a.get(1, 0) * a.get(2, 2) - a.get(1, 2) * a.get(2, 0)) + a.get(0, 2) *
			(a.get(1, 0) * a.get(2, 1) - a.get(1, 1) * a.get(2, 0))
		if math.abs(det) < tol {
			errno.vsl_panic('inverse of ($a.m x $a.n) matrix failed with zero determinant: |det(a)| = $det < $tol',
				.efailed)
		}
		ai.set(0, 0, (a.get(1, 1) * a.get(2, 2) - a.get(1, 2) * a.get(2, 1)) / det)
		ai.set(0, 1, (a.get(0, 2) * a.get(2, 1) - a.get(0, 1) * a.get(2, 2)) / det)
		ai.set(0, 2, (a.get(0, 1) * a.get(1, 2) - a.get(0, 2) * a.get(1, 1)) / det)
		ai.set(1, 0, (a.get(1, 2) * a.get(2, 0) - a.get(1, 0) * a.get(2, 2)) / det)
		ai.set(1, 1, (a.get(0, 0) * a.get(2, 2) - a.get(0, 2) * a.get(2, 0)) / det)
		ai.set(1, 2, (a.get(0, 2) * a.get(1, 0) - a.get(0, 0) * a.get(1, 2)) / det)
		ai.set(2, 0, (a.get(1, 0) * a.get(2, 1) - a.get(1, 1) * a.get(2, 0)) / det)
		ai.set(2, 1, (a.get(0, 1) * a.get(2, 0) - a.get(0, 0) * a.get(2, 1)) / det)
		ai.set(2, 2, (a.get(0, 0) * a.get(1, 1) - a.get(0, 1) * a.get(1, 0)) / det)
	} else {
		errno.vsl_panic('cannot compute inverse of ($a.m x $a.n) matrix with this function',
			.efailed)
	}
	return det
}

// matrix_svd performs the SVD decomposition
// Input:
// a     -- matrix a
// copy_a -- creates a copy of a; otherwise 'a' is modified
// Output:
// s  -- diagonal terms [must be pre-allocated] s.len = imin(a.m, a.n)
// u  -- left matrix [must be pre-allocated] u is (a.m x a.m)
// vt -- transposed right matrix [must be pre-allocated] vt is (a.n x a.n)
pub fn matrix_svd(s []f64, u, vt, a Matrix, copy_a bool) {
	superb := [0.0].repeat(int(math.min(a.m, a.n)))
	mut acpy := a
	if copy_a {
		acpy = a.clone()
	}
	blas.dgesvd(byte(`A`), byte(`A`), a.m, a.n, acpy.data, a.m, s, u.data, a.m, vt.data,
		a.n, superb)
}

// matrix_inv computes the inverse of a general matrix (square or not). It also computes the
// pseudo-inverse if the matrix is not square.
// Input:
// a -- input matrix (M x N)
// Output:
// ai -- inverse matrix (N x M)
// det -- determinant of matrix (ONLY if calc_det == true and the matrix is square)
// NOTE: the dimension of the ai matrix must be N x M for the pseudo-inverse
pub fn matrix_inv(mut ai Matrix, mut a Matrix, calc_det bool) f64 {
	mut det := 0.0
	// square inverse
	if a.m == a.n {
		ai.data = a.data.clone()
		ipiv := [0].repeat(int(math.min(a.m, a.n)))
		blas.dgetrf(a.m, a.n, mut ai.data, a.m, ipiv) // NOTE: ipiv are 1-based indices
		if calc_det {
			det = 1.0
			for i := 0; i < a.m; i++ {
				if ipiv[i] - 1 == i { // NOTE: ipiv are 1-based indices
					det = math.abs(det) * ai.get(i, i)
				} else {
					det = -det * ai.get(i, i)
				}
			}
		}
		blas.dgetri(a.n, mut ai.data, a.m, ipiv)
		return det
	}
	// singular value decomposition
	s := [0.0].repeat(int(math.min(a.m, a.n)))
	u := matrix(a.m, a.m)
	vt := matrix(a.n, a.n)
	matrix_svd(s, u, vt, a, true)
	// pseudo inverse
	tol_s := 1e-8 // TODO: improve this tolerance with a better estimate
	for i := 0; i < a.n; i++ {
		for j := 0; j < a.m; j++ {
			ai.set(i, j, 0)
			for k := 0; k < s.len; k++ {
				if s[k] > tol_s {
					ai.add(i, j, vt.get(k, i) * u.get(j, k) / s[k])
				}
			}
		}
	}
	return det
}

// matrix_cond_num returns the condition number of a square matrix using the inverse of this matrix;
// thus it is not as efficient as it could be, e.g. by using the SV decomposition.
// normtype -- Type of norm to use:
// "F" or "" => Frobenius
// "I"       => Infinite
pub fn matrix_cond_num(mut a Matrix, normtype string) f64 {
	mut res := 0.0
	mut ai := matrix(a.m, a.n)
	matrix_inv(mut ai, mut a, false)
	if normtype == 'I' {
		res = a.norm_inf() * ai.norm_inf()
		return res
	}
	res = a.norm_frob() * ai.norm_frob()
	return res
}
