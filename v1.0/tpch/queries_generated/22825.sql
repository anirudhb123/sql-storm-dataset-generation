WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_amount,
           COUNT(DISTINCT li.l_partkey) AS item_count
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE li.l_shipdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
RegionCustomer AS (
    SELECT r.r_regionkey, c.c_custkey, c.c_name, COALESCE(SUM(od.total_amount), 0) AS region_spend
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN OrderDetails od ON c.c_custkey = od.o_custkey
    GROUP BY r.r_regionkey, c.c_custkey, c.c_name
)
SELECT r.r_name, COUNT(DISTINCT rc.c_custkey) AS num_customers,
       SUM(CASE WHEN rc.region_spend > 0 THEN rc.region_spend ELSE NULL END) AS total_spending,
       AVG(CASE WHEN rc.region_spend > 0 THEN rc.region_spend ELSE NULL END) AS avg_spending_per_customer
FROM region r
JOIN RegionCustomer rc ON r.r_regionkey = rc.r_regionkey
LEFT JOIN SupplierHierarchy sh ON rc.c_custkey = sh.s_nationkey
WHERE (rc.region_spend > 1000 OR sh.level IS NOT NULL)
GROUP BY r.r_name
ORDER BY total_spending DESC, num_customers ASC
LIMIT 10;
