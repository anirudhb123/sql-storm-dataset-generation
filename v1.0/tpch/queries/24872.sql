
WITH RECURSIVE recursive_suppliers AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, s.s_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    WHERE ps.ps_availqty > 0
    UNION ALL
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, s.s_acctbal + 1
    FROM recursive_suppliers rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    WHERE ps.ps_availqty <= 0 AND s.s_acctbal < 1000
),
max_order_value AS (
    SELECT o.o_orderkey, MAX(o.o_totalprice) AS max_total
    FROM orders o
    GROUP BY o.o_orderkey
),
order_details AS (
    SELECT o.o_orderkey, COUNT(l.l_linenumber) AS total_lines, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey
),
filtered_nations AS (
    SELECT n.n_nationkey, n.n_name
    FROM nation n
    WHERE n.n_regionkey IS NOT NULL
),
supplier_revenue AS (
    SELECT rs.s_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM recursive_suppliers rs
    LEFT JOIN lineitem l ON rs.ps_partkey = l.l_partkey
    GROUP BY rs.s_suppkey
)
SELECT fn.n_nationkey, fn.n_name, od.o_orderkey, od.total_lines, od.total_revenue, 
       COALESCE(s.s_name, 'No Supplier') AS supplier_name, 
       COALESCE(sr.supplier_revenue, 0) AS supplier_total_revenue
FROM filtered_nations fn
FULL OUTER JOIN order_details od ON fn.n_nationkey = od.o_orderkey % 10
LEFT JOIN supplier_revenue sr ON sr.s_suppkey = fn.n_nationkey
LEFT JOIN supplier s ON s.s_nationkey = fn.n_nationkey
WHERE od.total_lines > 1 
  AND od.total_revenue IS NOT NULL
  AND (s.s_acctbal IS NULL OR s.s_acctbal / NULLIF(sr.supplier_revenue, 0) > 1)
ORDER BY fn.n_nationkey, od.total_revenue DESC;
