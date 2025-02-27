WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
TotalSales AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
HighRevenueOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, ts.total_revenue
    FROM orders o
    JOIN TotalSales ts ON o.o_orderkey = ts.o_orderkey
    WHERE ts.total_revenue > 100000
),
NationSales AS (
    SELECT n.n_name, SUM(ts.total_revenue) AS total_nation_revenue
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN TotalSales ts ON l.l_orderkey = ts.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
),
EnrichedCustomer AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
        CASE WHEN c.c_acctbal IS NULL THEN 0 ELSE c.c_acctbal END AS adjusted_acctbal
    FROM customer c
)
SELECT 
    nh.n_name,
    SUM(nr.total_nation_revenue) AS total_revenue_by_nation,
    AVG(ec.adjusted_acctbal) AS avg_customer_acctbal,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(o.o_orderdate) AS last_order_date
FROM NationSales nr
LEFT OUTER JOIN nation nh ON nr.n_nationkey = nh.n_nationkey
JOIN HighRevenueOrders o ON o.o_orderdate = nr.total_nation_revenue
JOIN EnrichedCustomer ec ON ec.c_custkey = o.o_orderkey
GROUP BY nh.n_name
HAVING SUM(nr.total_nation_revenue) > 50000
ORDER BY total_revenue_by_nation DESC, avg_customer_acctbal DESC;
