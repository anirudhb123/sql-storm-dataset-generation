WITH RecursiveSupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, r.level + 1
    FROM supplier s
    JOIN RecursiveSupplierCTE r ON s.s_nationkey = r.s_nationkey
    WHERE s.s_acctbal > r.s_acctbal
),
AggregatedLineItems AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(*) AS line_item_count
    FROM lineitem l
    WHERE l.l_shipdate >= '2022-01-01' AND l.l_shipdate < '2023-01-01'
    GROUP BY l.l_orderkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, 
           o.o_orderkey, 
           COALESCE(a.total_revenue, 0) AS total_revenue
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN AggregatedLineItems a ON o.o_orderkey = a.l_orderkey
    WHERE c.c_acctbal > 5000
)
SELECT r.r_name,
       SUM(co.total_revenue) AS region_revenue,
       COUNT(DISTINCT co.c_custkey) AS unique_customers,
       MAX(cs.s_acctbal) AS top_supplier_acctbal
FROM CustomerOrders co
JOIN nation n ON co.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN RecursiveSupplierCTE cs ON cs.s_nationkey = n.n_nationkey
GROUP BY r.r_name
HAVING region_revenue > 100000
ORDER BY region_revenue DESC;
