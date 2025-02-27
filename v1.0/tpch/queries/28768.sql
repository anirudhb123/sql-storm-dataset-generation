SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(s.s_acctbal) AS max_supplier_acctbal,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), ', ') AS suppliers_info,
    CASE 
        WHEN AVG(l.l_discount) > 0.1 THEN 'High Discount'
        WHEN AVG(l.l_discount) BETWEEN 0.05 AND 0.1 THEN 'Medium Discount'
        ELSE 'Low Discount'
    END AS discount_category
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
    r.r_name LIKE 'Europe%' AND 
    c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type
HAVING 
    SUM(l.l_discount) > 0.15
ORDER BY 
    total_quantity DESC, avg_extended_price DESC
LIMIT 100;
