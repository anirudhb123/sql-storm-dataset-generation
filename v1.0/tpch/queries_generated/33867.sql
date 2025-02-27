WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.n_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal > 0
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.n_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.n_nationkey = sh.n_nationkey
    WHERE sh.rank <= 5 AND s.s_suppkey != sh.s_suppkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_custkey) AS customers_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey, o.o_orderdate
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT nh.n_name, SUM(od.total_revenue) AS total_revenue, MAX(od.customers_count) AS max_customers,
       COUNT(DISTINCT sh.s_suppkey) AS suppliers_count
FROM OrderDetails od
JOIN NationRegion nr ON nr.n_regionkey = (SELECT r.r_regionkey 
                                           FROM region r 
                                           WHERE r.r_name = 'AMERICA')
JOIN supplier s ON s.s_nationkey = nr.n_nationkey
JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
LEFT JOIN orders o ON o.o_orderkey = od.o_orderkey
WHERE o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
GROUP BY nh.n_name
HAVING SUM(od.total_revenue) > 10000
ORDER BY total_revenue DESC;
