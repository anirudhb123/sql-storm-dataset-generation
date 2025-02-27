WITH RECURSIVE SupplierCTE AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS Level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, Level + 1
    FROM supplier s
    JOIN SupplierCTE cte ON s.s_nationkey = cte.s_nationkey
    WHERE s.s_acctbal > cte.s_acctbal
),
PartCounts AS (
    SELECT ps_partkey, COUNT(ps_suppkey) AS supp_count
    FROM partsupp
    GROUP BY ps_partkey
),
RecentOrders AS (
    SELECT o_orderkey, o_custkey, o_orderdate,
           DENSE_RANK() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS order_rank
    FROM orders
    WHERE o_orderdate > CURRENT_DATE - INTERVAL '1 month'
),
AggregatedShipments AS (
    SELECT l_shipmode, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
           SUM(l_quantity) AS total_quantity
    FROM lineitem
    WHERE l_shipdate BETWEEN CURRENT_DATE - INTERVAL '1 year' AND CURRENT_DATE
    GROUP BY l_shipmode
)
SELECT r.r_name, 
       COUNT(DISTINCT nc.n_nationkey) AS distinct_nations,
       SUM(COALESCE(cte.s_acctbal, 0)) AS total_account_balance,
       AVG(a.total_revenue) AS avg_revenue,
       MAX(d.supp_count) AS max_suppliers_for_part
FROM region r
LEFT JOIN nation nc ON r.r_regionkey = nc.n_regionkey
LEFT JOIN SupplierCTE cte ON cte.s_nationkey = nc.n_nationkey
LEFT JOIN RecentOrders o ON o.o_custkey = nc.n_nationkey
LEFT JOIN AggregatedShipments a ON o.o_orderkey = a.l_orderkey
LEFT JOIN PartCounts d ON d.ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = cte.s_suppkey)
WHERE r.r_name LIKE '%Region%'
AND EXISTS (
    SELECT 1
    FROM customer c
    WHERE c.c_nationkey = nc.n_nationkey AND c.c_acctbal IS NOT NULL
)
GROUP BY r.r_name
HAVING COUNT(DISTINCT nc.n_nationkey) > 1
ORDER BY total_account_balance DESC, r.r_name ASC;
