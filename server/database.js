const Pool = require('pg').Pool;
const pool = new Pool({
    user: 'postgres',
    password: 'Ghoughou*2001',
    host: 'localhost',
    port: 5432,
    database: 'BANK'
});
module.exports = pool;
