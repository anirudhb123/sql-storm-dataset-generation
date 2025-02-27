WITH RECURSIVE SupplyHierarchy AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost, 1 AS level
    FROM partsupp
    WHERE ps_availqty > 0

    UNION ALL

    SELECT p.ps_partkey, p.ps_suppkey, p.ps_availqty, p.ps_supplycost, sh.level + 1
    FROM partsupp p
    JOIN SupplyHierarchy sh ON p.ps_suppkey = sh.ps_suppkey
    WHERE p.ps_availqty > 0 AND sh.level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
),
SupplierSummary AS (
    SELECT s.s_suppkey, SUM(sh.ps_supplycost * sh.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN SupplyHierarchy sh ON s.s_suppkey = sh.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT r.r_name, n.n_name, SUM(os.total_revenue) AS total_revenue, 
       COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
       CASE WHEN SUM(os.total_revenue) IS NULL THEN 'No Revenue' ELSE 'Revenue Exists' END AS revenue_status
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN OrderSummary os ON c.c_custkey = os.o_orderkey
LEFT JOIN SupplierSummary ss ON os.o_orderkey = ss.s_suppkey
WHERE (r.r_name LIKE 'Asia%' OR n.n_name LIKE 'United%')
  AND ss.total_supply_cost IS NOT NULL
GROUP BY r.r_name, n.n_name
HAVING COUNT(os.o_orderkey) > 0
ORDER BY total_revenue DESC, total_supply_cost ASC;
