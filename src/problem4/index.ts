/**
 * Return the summation 1 + 2 + ... + n
 * Assumes n is a non-negative integer and result < Number.MAX_SAFE_INTEGER
 */

/**
 * Iterative accumulation using a simple for-loop.
 * Time: O(n)  |  Space: O(1)
 */
export function sum_to_n_a(n: number): number {
    let total = 0;
    for (let i = 1; i <= n; i += 1) {
        total += i;
    }
    return total;
}

/**
 * Closed-form (Gauss) formula: n * (n + 1) / 2
 * Time: O(1)  |  Space: O(1)
 */
export function sum_to_n_b(n: number): number {
    return (n * (n + 1)) / 2;
}

/**
 * Two-pointer pairing technique: add low and high moving towards the center.
 * Equivalent to summing pairs (1 + n), (2 + n-1), ...
 * Time: O(n)  |  Space: O(1)
 */
export function sum_to_n_c(n: number): number {
    let left = 1;
    let right = n;
    let total = 0;

    while (left < right) {
        total += left + right;
        left += 1;
        right -= 1;
    }

    if (left === right) {
        total += left; // middle term when n is odd
    }

    return total;
}


