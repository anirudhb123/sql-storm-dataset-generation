SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(CASE WHEN l_discount > 0.1 THEN l_extendedprice * (1 - l_discount) ELSE l_extendedprice END) AS total_discounted_sales,
    AVG(l_quantity) AS avg_quantity_per_line,
    MAX(l_shipdate) AS latest_shipdate,
    MIN(l_shipdate) AS earliest_shipdate,
    STRING_AGG(DISTINCT CONCAT('Supplier ', s.s_name, ' in ', n.n_name), ', ') AS supplier_details
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
WHERE 
    p.p_retailprice > 100.00
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_discounted_sales DESC
LIMIT 10;
