SELECT 
    p.p_mfgr,
    p.p_brand,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(CASE 
        WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice * (1 - l.l_discount) 
        ELSE 0 
    END) AS avg_filled_order_value,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%plastic%' AND
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_mfgr, p.p_brand
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    supplier_count DESC, total_quantity DESC;