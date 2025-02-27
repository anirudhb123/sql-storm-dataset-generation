WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS depth
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.depth + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
)

SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    (SELECT AVG(ps_availqty) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS avg_supply_quantity
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
WHERE 
    l.l_shipdate >= '2022-01-01' AND l.l_shipdate < '2023-01-01'
    AND (o.o_orderstatus = 'F' OR o.o_orderstatus IS NULL)
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(l_extendedprice) FROM lineitem WHERE l_shipdate >= '2022-01-01')
ORDER BY 
    total_revenue DESC
LIMIT 10;
