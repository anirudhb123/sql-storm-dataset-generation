SELECT 
    CONCAT(c.c_name, ' from ', n.n_name, ' with an account balance of ', FORMAT(c.c_acctbal, 2)) AS customer_info,
    STRING_AGG(CONCAT(p.p_name, ' (', p.p_brand, ') - ', p.p_comment), '; ') AS parts_details
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    l.l_shipdate BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 YEAR) AND CURDATE() 
    AND p.p_retailprice > 50.00
GROUP BY 
    c.c_custkey, n.n_nationkey
ORDER BY 
    c.c_name, n.n_name;
