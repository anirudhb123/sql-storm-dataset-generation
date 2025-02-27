WITH RECURSIVE NationHierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 0 AS level
    FROM nation n
    WHERE n.n_regionkey IS NOT NULL
    UNION ALL
    SELECT nh.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM NationHierarchy nh
    JOIN nation n ON nh.n_nationkey = n.n_nationkey
    WHERE nh.level < 5
), 
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderAnalysis AS (
    SELECT o.o_orderkey, o.o_custkey, 
           DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank,
           AVG(l.l_discount) OVER (PARTITION BY o.o_custkey) AS avg_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate < cast('1998-10-01' as date) - INTERVAL '30 days'
),
FilteredCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
)
SELECT n.n_name, s.total_supply_value, o.order_rank, c.total_spent
FROM NationHierarchy n
FULL OUTER JOIN SupplierStats s ON n.n_nationkey = s.s_suppkey
LEFT JOIN OrderAnalysis o ON o.o_custkey = n.n_nationkey
JOIN FilteredCustomers c ON c.c_custkey = n.n_nationkey
WHERE (s.total_supply_value IS NULL OR s.total_supply_value > 50000)
  AND (o.order_rank IS NULL OR o.order_rank <= 5)
  AND COALESCE(c.total_spent, 0) BETWEEN 1000 AND 10000
ORDER BY n.n_name, total_supply_value DESC NULLS LAST;