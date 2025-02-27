WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CAST(s.s_name AS varchar(255)) AS full_name, 
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, 
           CAST(CONCAT(sh.full_name, ' -> ', s2.s_name) AS varchar(255)),
           sh.level + 1
    FROM supplier s2
    JOIN supplier_hierarchy sh ON s2.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
customer_summary AS (
    SELECT c.c_nationkey, 
           COUNT(DISTINCT c.c_custkey) AS total_customers, 
           SUM(c.c_acctbal) AS total_acct_balance
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 500
    GROUP BY c.c_nationkey
),
supplier_performance AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           p.p_name, s.s_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, p.p_name, s.s_name
),
final_report AS (
    SELECT sh.s_suppkey, sh.full_name, cs.total_customers, cs.total_acct_balance, 
           sp.p_name, sp.revenue
    FROM supplier_hierarchy sh
    LEFT JOIN customer_summary cs ON sh.s_nationkey = cs.c_nationkey
    LEFT JOIN supplier_performance sp ON sh.s_suppkey = sp.ps_suppkey
    WHERE cs.total_customers IS NOT NULL OR sp.revenue IS NOT NULL
)
SELECT f.s_suppkey, f.full_name, f.total_customers,
       COALESCE(f.total_acct_balance, 0) AS total_acct_balance,
       COALESCE(f.revenue, 0) AS revenue
FROM final_report f
ORDER BY f.total_acct_balance DESC, f.revenue DESC
LIMIT 100;
