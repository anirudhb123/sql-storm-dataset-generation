SELECT 
    CONCAT('Part Name: ', p_name, ' | Manufacturer: ', p_mfgr, ' | Type: ', p_type) AS part_info,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT s_name ORDER BY s_name SEPARATOR ', '), ',', 3) AS top_suppliers,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
    p.p_size > 10 
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND s.s_acctbal > 1000
GROUP BY 
    p.p_partkey
ORDER BY 
    total_revenue DESC
LIMIT 10;
