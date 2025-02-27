SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(L.l_quantity * L.l_extendedprice) AS total_revenue,
    STRING_AGG(DISTINCT CONCAT(p.p_mfgr, ' - ', p.p_type), '; ') AS part_details
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem L ON p.p_partkey = L.l_partkey
JOIN 
    orders o ON L.l_orderkey = o.o_orderkey
WHERE 
    s.s_acctbal > 5000 
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(L.l_quantity * L.l_extendedprice) > 10000
ORDER BY 
    total_revenue DESC;