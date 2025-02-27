WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey,
           CAST(s.s_name AS VARCHAR(100)) AS full_name,
           LENGTH(s.s_name) AS name_length,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey,
           CONCAT(sh.full_name, ' -> ', s.s_name) AS full_name,
           LENGTH(CONCAT(sh.full_name, ' -> ', s.s_name)) AS name_length,
           ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier_hierarchy sh
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey
    WHERE sh.rank < 5
),
order_summary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_custkey) AS unique_customers,
           AVG(l.l_quantity) AS avg_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY o.o_orderkey
),
nation_details AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acct_bal
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT d.region_name, d.n_name, d.supplier_count, d.total_acct_bal,
       COALESCE(os.total_revenue, 0) AS total_revenue,
       COALESCE(os.unique_customers, 0) AS unique_customers,
       MAX(sh.name_length) AS max_supplier_name_length,
       MIN(sh.rank) AS min_supplier_rank
FROM nation_details d
LEFT JOIN order_summary os ON d.n_nationkey = os.o_orderkey
LEFT JOIN supplier_hierarchy sh ON d.n_nationkey = sh.s_nationkey
GROUP BY d.region_name, d.n_name, d.supplier_count, d.total_acct_bal
HAVING SUM(CASE WHEN sh.s_name IS NULL THEN 1 ELSE 0 END) < 3
   OR COUNT(sh.s_suppkey) > 5
ORDER BY d.total_acct_bal DESC, d.supplier_count ASC;
