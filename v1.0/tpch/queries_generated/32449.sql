WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey,
           l.l_quantity, l.l_extendedprice,
           l.l_discount, l.l_shipdate,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rnk
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01'
      AND l.l_shipdate < '2024-01-01'
      AND l.l_discount BETWEEN 0.05 AND 0.10
),
TotalSupplyCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM partsupp ps
    JOIN FilteredLineItems l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    STRING_AGG(DISTINCT p.p_name, ', ') AS associated_parts
FROM orders o
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN TotalSupplyCost tsc ON l.l_partkey = tsc.ps_partkey
JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
JOIN part p ON l.l_partkey = p.p_partkey
WHERE (n.n_name NOT LIKE '%land%' OR n.n_name IS NULL)
  AND (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
GROUP BY n.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
   AND COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY net_revenue DESC;
