SELECT 
    CONCAT(s.s_name, ' has supplied ', SUM(ps.ps_availqty), ' units of ', p.p_name) AS supply_summary,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT n.n_name SEPARATOR ', '), ',', 3) AS nations_supplied,
    MAX(o.o_orderdate) AS last_order_date
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    o.o_orderstatus = 'O'
    AND p.p_retailprice > 100.00
GROUP BY 
    s.s_suppkey
HAVING 
    SUM(ps.ps_availqty) > 1000
ORDER BY 
    last_order_date DESC
LIMIT 10;
