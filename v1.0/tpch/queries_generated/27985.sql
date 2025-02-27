SELECT 
    SUBSTRING(p.p_name, 1, 15) AS short_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    MAX(CASE WHEN p.p_size > 20 THEN p.p_retailprice ELSE NULL END) AS max_retailprice_large,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations,
    CONCAT('Total ', SUM(l.l_quantity), ' items, Average Price ', ROUND(AVG(l.l_extendedprice), 2)) AS item_summary
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey 
JOIN 
    customer c ON c.c_custkey = l.l_orderkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
WHERE 
    p.p_comment LIKE '%blue%' 
GROUP BY 
    SUBSTRING(p.p_name, 1, 15)
ORDER BY 
    supplier_count DESC
LIMIT 10;
