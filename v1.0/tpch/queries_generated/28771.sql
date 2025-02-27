SELECT 
    p.p_partkey, 
    p.p_name, 
    CONCAT(s.s_name, ' (', s.s_phone, ')') AS supplier_info,
    SUBSTRING_INDEX(p.p_comment, ' ', 5) AS short_comment,
    COUNT(DISTINCT c.c_custkey) AS number_of_customers,
    SUM(l.l_quantity) AS total_quantity,
    ROUND(AVG(p.p_retailprice), 2) AS avg_retail_price,
    MIN(l.l_shipdate) AS first_ship_date,
    MAX(l.l_shipdate) AS last_ship_date
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE '%widget%'
    AND s.s_nationkey = (
        SELECT n.n_nationkey 
        FROM nation n, region r 
        WHERE r.r_regionkey = n.n_regionkey AND r.r_name = 'ASIA'
    )
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    supplier_info
HAVING 
    total_quantity > 100
ORDER BY 
    total_quantity DESC;
