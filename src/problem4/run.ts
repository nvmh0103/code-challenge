import { sum_to_n_a, sum_to_n_b, sum_to_n_c } from './index';

const nArg = process.argv[2];
const n = nArg ? Number(nArg) : 5;

console.log('n =', n);
console.log('sum_to_n_a:', sum_to_n_a(n));
console.log('sum_to_n_b:', sum_to_n_b(n));
console.log('sum_to_n_c:', sum_to_n_c(n));


