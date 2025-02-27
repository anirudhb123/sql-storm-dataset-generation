WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name LIKE 'United%')

    UNION ALL

    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, sh.level + 1
    FROM supplier s2
    JOIN SupplierHierarchy sh ON s2.s_nationkey = sh.s_nationkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    SUM(COALESCE(ps.ps_supplycost, 0)) AS total_supply_cost,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_quantity) DESC) AS rank_within_part
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_retailprice > 100.00
    AND l.l_shipdate >= DATE '1997-01-01'
    AND (l.l_returnflag IS NULL OR l.l_returnflag <> 'R')
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_supply_cost DESC, rank_within_part
LIMIT 10;