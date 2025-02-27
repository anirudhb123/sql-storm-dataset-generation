SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(p.p_retailprice) AS max_retail_price,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice ELSE 0 END) AS finalized_sales,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size > 20 AND 
    SUBSTRING(p.p_comment, 1, 10) = 'excellent'
GROUP BY 
    p.p_name
ORDER BY 
    supplier_count DESC, avg_supply_cost ASC
LIMIT 100;
