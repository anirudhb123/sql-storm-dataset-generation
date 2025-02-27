WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 50
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' 
    AND o.o_orderdate <= DATE '1997-12-31'
),
total_sales AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT n.n_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS finalized_sales,
       AVG(COALESCE(sh.s_acctbal, 0)) AS avg_supplier_balance,
       MIN(sh.level) AS min_supplier_level
FROM nation n
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN ranked_orders o ON c.c_custkey = o.o_custkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = n.n_nationkey
JOIN total_sales ts ON ts.l_orderkey = o.o_orderkey
WHERE n.n_comment IS NOT NULL
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY finalized_sales DESC, customer_count ASC;