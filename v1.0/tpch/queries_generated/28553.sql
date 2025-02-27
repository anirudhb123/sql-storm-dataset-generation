SELECT 
    CONCAT('Supplier: ', s_name, ' (Nation: ', n_name, ') - ', 
           'Orders Count: ', COUNT(DISTINCT o_orderkey), 
           ', Total Extended Price: ', SUM(l_extendedprice), 
           ', Avg Discount: ', AVG(l_discount), 
           ' [Comment: ', s_comment, ']') AS supplier_summary
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    o.o_orderstatus = 'O' 
    AND l_shipdate >= '2023-01-01' 
    AND l_shipdate < '2024-01-01'
GROUP BY 
    s.suppkey, s_name, n_name, s_comment
ORDER BY 
    SUM(l_extendedprice) DESC
LIMIT 10;
