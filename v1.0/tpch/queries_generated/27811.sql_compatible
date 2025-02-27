
SELECT 
    p.p_name,
    s.s_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_discount) AS average_discount,
    MAX(l.l_extendedprice) AS max_price,
    MIN(l.l_tax) AS min_tax,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' (', c.c_mktsegment, ')'), ', ') AS customers,
    rg.r_name AS region_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region rg ON n.n_regionkey = rg.r_regionkey
WHERE 
    p.p_comment LIKE '%fragile%'
    AND s.s_acctbal > 1000.00
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, rg.r_name
HAVING 
    SUM(l.l_quantity) > 500
ORDER BY 
    total_quantity DESC, average_discount DESC;
