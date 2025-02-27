SELECT 
    CONCAT('Supplier: ', s_name, ' | Region: ', r_name, ' | Total Supply Cost: $', 
           FORMAT(SUM(ps_supplycost * ps_availqty), 2), 
           ' | Part Types Supplied: ', 
           GROUP_CONCAT(DISTINCT p_type ORDER BY p_type SEPARATOR ', ')) AS Supplier_Info
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    s.s_acctbal > 1000.00 
    AND r.r_name LIKE '%West%'
GROUP BY 
    s.s_suppkey, r.r_regionkey
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    Total_Supply_Cost DESC
LIMIT 10;
