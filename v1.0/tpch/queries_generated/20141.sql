WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 0 AS level
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_custkey = ch.c_custkey
    WHERE ch.level < 5
),
AvgSupplierCost AS (
    SELECT ps.s_suppkey, 
           AVG(ps.ps_supplycost) AS avg_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM partsupp ps
    GROUP BY ps.s_suppkey
),
OrderStats AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           COUNT(DISTINCT l.l_orderkey) AS line_count,
           FIRST_VALUE(l.l_shipdate) OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate) AS first_ship,
           LAST_VALUE(l.l_shipdate) OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_ship
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'P')
    GROUP BY o.o_orderkey
)
SELECT 
    ph.p_partkey,
    ph.p_name,
    n.n_name AS nation_name,
    COALESCE(gs.total_revenue, 0) AS total_revenue,
    (SELECT SUM(sub_query.revenue) 
     FROM OrderStats sub_query
     WHERE sub_query.line_count > 3) AS grand_revenue,
    CASE 
        WHEN ps.avg_cost IS NULL THEN 'No Supplier'
        ELSE 'Supplier Exists'
    END AS supplier_status
FROM part ph
LEFT JOIN partsupp ps ON ph.p_partkey = ps.ps_partkey
LEFT JOIN AvgSupplierCost avg_ps ON ps.ps_suppkey = avg_ps.s_suppkey
LEFT JOIN nation n ON n.n_nationkey = (
    SELECT c.c_nationkey 
    FROM customer c 
    WHERE c.c_custkey = ANY (SELECT ch.c_custkey FROM CustomerHierarchy ch)
    LIMIT 1
)
LEFT JOIN (
    SELECT ps.ps_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l 
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY ps.ps_partkey
) AS gs ON ph.p_partkey = gs.ps_partkey
WHERE (ph.p_retailprice > 100 OR ph.p_size IS NULL)
  AND (AVG(ps.ps_supplycost) < 50 OR ps.ps_supplycost IS NOT NULL)
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
