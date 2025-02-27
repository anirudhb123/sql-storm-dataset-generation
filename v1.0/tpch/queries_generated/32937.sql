WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
), 
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_custkey) AS customer_count,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT p.p_name, 
       MAX(COALESCE(ps.ps_availqty, 0)) AS max_avail_qty,
       AVG(s.s_acctbal) AS avg_acct_balance,
       MIN(oss.total_revenue) AS min_order_revenue,
       SUM(CASE WHEN c.c_mktsegment = 'BUILDING' THEN 1 ELSE 0 END) AS building_customers
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN customer c ON s.s_nationkey = c.c_nationkey
LEFT JOIN (SELECT o_orderkey, total_revenue 
            FROM OrderStats 
            WHERE revenue_rank < 10) oss ON oss.o_orderkey = ps.ps_partkey
JOIN region r ON s.s_nationkey = r.r_regionkey
GROUP BY p.p_name
HAVING COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY avg_acct_balance DESC, max_avail_qty ASC;
