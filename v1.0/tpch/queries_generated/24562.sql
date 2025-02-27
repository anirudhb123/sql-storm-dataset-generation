WITH RECURSIVE SupplierHierarchy AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CAST(s.s_name AS varchar(255)) AS full_name,
        0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT
        sp.ps_suppkey,
        sp.s_name,
        sp.s_nationkey,
        CONCAT(sh.full_name, ' -> ', sp.s_name) AS full_name,
        sh.level + 1
    FROM partsupp ps
    JOIN supplier sp ON ps.ps_suppkey = sp.s_suppkey
    JOIN SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
    WHERE sh.level < 5
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN o.o_orderstatus IN ('F', 'O') THEN o.o_totalprice ELSE 0 END) AS cum_totalprice,
    AVG(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) AS avg_revenue_per_lineitem,
    STRING_AGG(DISTINCT CONCAT(sp.full_name, ' (Level: ', sp.level, ')'), ', ') AS supplier_hierarchy
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN SupplierHierarchy sp ON sp.s_nationkey = c.c_nationkey
WHERE r.r_name LIKE 'E%' 
  AND (l.l_returnflag = 'R' OR l.l_returnflag IS NULL)
  AND (sp.s_suppkey IS NOT NULL OR sp.s_suppkey IS NULL)
GROUP BY r.r_name, n.n_name
HAVING AVG(l.l_quantity) > (SELECT AVG(l2.l_quantity) FROM lineitem l2 WHERE l2.l_returnflag = 'N')
ORDER BY customer_count DESC, cum_totalprice ASC;
