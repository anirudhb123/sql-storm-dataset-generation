WITH RECURSIVE CTE_SupplierChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, c.level + 1
    FROM partsupp ps
    JOIN CTE_SupplierChain c ON ps.ps_suppkey = c.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)

SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    AVG(o.o_totalprice) AS avg_order_value,
    SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) END) AS total_discounted_sales,
    STRING_AGG(DISTINCT p.p_name, ', ') AS products_sold,
    r.r_name AS region_name
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE '%West%'
    AND (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
GROUP BY 
    n.n_name, r.r_name
HAVING 
    AVG(o.o_totalprice) > 1000
ORDER BY 
    total_customers DESC, avg_order_value DESC;
