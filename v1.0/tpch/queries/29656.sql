
SELECT 
    p.p_name,
    s.s_name AS supplier_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(l.l_shipdate) AS last_ship_date,
    MIN(l.l_shipdate) AS first_ship_date,
    AVG(l.l_discount) AS average_discount,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supply,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, p.p_comment
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC;
