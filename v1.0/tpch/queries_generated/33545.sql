WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level_id
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level_id + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
DenseRankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_shippriority,
        o.o_totalprice,
        DENSE_RANK() OVER (ORDER BY os.total_revenue DESC) AS order_rank
    FROM OrderStats os
    JOIN orders o ON os.o_orderkey = o.o_orderkey
)
SELECT 
    r.r_name AS region_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END) AS total_returned,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    MAX(dro.order_rank) AS highest_order_rank,
    AVG(s.s_acctbal) AS average_supplier_balance
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN customer c ON s.s_nationkey = c.c_nationkey
JOIN lineitem l ON s.s_suppkey = l.l_suppkey
JOIN DenseRankedOrders dro ON l.l_orderkey = dro.o_orderkey
WHERE s.s_acctbal IS NOT NULL
GROUP BY r.r_name
HAVING AVG(s.s_acctbal) > (SELECT AVG(s_acctbal) FROM supplier)
ORDER BY total_returned DESC;
