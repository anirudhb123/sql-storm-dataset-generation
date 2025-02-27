SELECT 
    CONCAT('Supplier: ', s_name, ' (', s_nationkey, ') - ', 
           'Total Parts Supplied: ', COUNT(DISTINCT ps_partkey), ' Items') AS Supplier_Info,
    GROUP_CONCAT(DISTINCT CONCAT('Part Name: ', p_name, ', Type: ', p_type) ORDER BY p_name SEPARATOR '; ') AS Supplied_Parts,
    SUM(l_extendedprice * (1 - l_discount)) AS Total_Revenue
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    AND l_linenumber IN (SELECT MAX(l_linenumber) FROM lineitem GROUP BY l_orderkey)
GROUP BY 
    s.s_suppkey
HAVING 
    Total_Revenue > 10000
ORDER BY 
    Total_Revenue DESC
LIMIT 10;
