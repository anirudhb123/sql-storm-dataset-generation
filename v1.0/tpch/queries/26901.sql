SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    MAX(p.p_retailprice) AS max_price,
    MIN(p.p_retailprice) AS min_price,
    AVG(p.p_retailprice) AS avg_price,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers_names,
    CASE 
        WHEN COUNT(DISTINCT ps.ps_suppkey) > 5 THEN 'Highly Sourced' 
        ELSE 'Low Supply'
    END AS supply_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    avg_price DESC, supplier_count DESC;
