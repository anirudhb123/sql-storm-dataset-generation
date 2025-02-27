WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
)
SELECT 
    p.p_name,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_extendedprice * (1 - li.l_discount) END) AS total_returned,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(li.l_extendedprice) DESC) as price_rank,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(li.l_extendedprice) DESC) as row_num,
    R.PLATFORM_DIMENSION AS dimension FROM
    part p
LEFT JOIN lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN orders o ON li.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN region r ON c.c_nationkey = r.r_regionkey
WHERE 
    (li.l_discount > 0.1 OR li.l_tax < 0.05)
    AND p.p_retailprice IS NOT NULL
    AND EXISTS (
        SELECT 1
        FROM SupplierHierarchy sh
        WHERE sh.s_nationkey = c.c_nationkey
    )
GROUP BY 
    p.p_name,
    R.PLATFORM_DIMENSION
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
ORDER BY 
    total_returned DESC,
    price_rank ASC;
