WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, sh.s_name, sh.s_acctbal
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.rank < 5
), order_summary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_custkey) AS unique_customers,
           MAX(o.o_totalprice) AS max_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY o.o_orderkey
), regions AS (
    SELECT r.r_regionkey, r.r_name, 
           COUNT(DISTINCT n.n_nationkey) AS total_nations
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT r.r_name,
       COALESCE(os.total_revenue, 0) AS total_revenue,
       COALESCE(sh.s_acctbal, 0) AS supplier_balance,
       os.unique_customers,
       CASE 
           WHEN os.max_order_value IS NULL THEN 'No Orders'
           WHEN os.max_order_value > 100000 THEN 'High Value'
           ELSE 'Regular Value'
       END AS order_value_category
FROM regions r
LEFT JOIN order_summary os ON r.total_nations = os.unique_customers
FULL OUTER JOIN supplier_hierarchy sh ON r.r_regionkey = sh.s_suppkey
WHERE r.r_name IS NOT NULL OR sh.s_suppkey IS NULL
ORDER BY r.r_name DESC, total_revenue DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
