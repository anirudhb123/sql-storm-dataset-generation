SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice - l.l_discount) AS avg_price_after_discount,
    CONCAT(c.c_name, ' (', c.custkey, ')') AS customer_info,
    r.r_name AS region_name
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem AS l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders AS o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer AS c ON o.o_custkey = c.c_custkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation AS n ON s.s_nationkey = n.n_nationkey
JOIN 
    region AS r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%fragile%'
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    short_name, r.r_name, customer_info
HAVING 
    total_quantity > 100
ORDER BY 
    r.r_name, total_quantity DESC;
