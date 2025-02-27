SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    SUM(l.l_quantity) AS total_quantity_ordered,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    MAX(o.o_orderdate) AS latest_order_date
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
WHERE 
    p.p_size BETWEEN 10 AND 30
    AND s.s_acctbal > 5000
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    total_quantity_ordered DESC;
