SELECT 
    CONCAT('Supplier: ', s_name, ' (', s_nationkey, ')', ' | ', 
           'Part: ', p_name, ' | ', 
           'Type: ', p_type, ' | ', 
           'Retail Price: $', FORMAT(p_retailprice, 2), ' | ', 
           'Total Order Qty: ', SUM(l_quantity), ' | ', 
           'Total Sales: $', FORMAT(SUM(l_extendedprice * (1 - l_discount)), 2)) AS Benchmark_String_Processing
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey AND s.s_suppkey = l.l_suppkey
GROUP BY 
    s.s_suppkey, p.p_partkey, s_name, p_name, p_type, p_retailprice
HAVING 
    SUM(l_quantity) > 100
ORDER BY 
    Total_Sales DESC
LIMIT 10;
