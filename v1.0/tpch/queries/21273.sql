
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
AggregatedPart AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
OrderAggregation AS (
    SELECT o.o_custkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY o.o_custkey
),
FilteredNation AS (
    SELECT n.n_nationkey, 
           n.n_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE n.n_comment IS NOT NULL
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(DISTINCT s.s_suppkey) > 0
)
SELECT ph.r_name, 
       sh.s_name,
       pa.total_supply_value,
       oa.total_revenue,
       oa.order_count,
       fn.supplier_count
FROM region ph
JOIN supplier sh ON ph.r_regionkey = sh.s_nationkey
LEFT JOIN AggregatedPart pa ON sh.s_suppkey = pa.p_partkey
JOIN OrderAggregation oa ON sh.s_nationkey = oa.o_custkey
FULL OUTER JOIN FilteredNation fn ON fn.n_nationkey = sh.s_nationkey
WHERE (oa.total_revenue > 10000 OR pa.total_supply_value IS NULL) 
  AND (fn.supplier_count IS NOT NULL AND fn.supplier_count >= 5)
ORDER BY ph.r_name, fn.supplier_count DESC
LIMIT 100 OFFSET 10;
