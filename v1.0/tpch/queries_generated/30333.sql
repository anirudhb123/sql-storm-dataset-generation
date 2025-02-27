WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 10 AND sh.level < 5
),
order_summary AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           SUM(l.l_quantity) AS total_quantity,
           CASE 
               WHEN o.o_totalprice > 1000 THEN 'High'
               WHEN o.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium'
               ELSE 'Low'
           END AS price_category
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
),
nation_stats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
           SUM(COALESCE(s.s_acctbal, 0)) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT n.n_name, n_stats.unique_suppliers, 
       n_stats.total_acctbal, 
       o_summary.price_category, 
       COUNT(DISTINCT sh.s_suppkey) AS total_suppliers_in_hierarchy
FROM nation_stats n_stats
JOIN nation n ON n.n_nationkey = n_stats.n_nationkey
LEFT JOIN order_summary o_summary ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = o_summary.o_orderkey))
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
WHERE n_stats.total_acctbal IS NOT NULL AND n_stats.unique_suppliers > 0
GROUP BY n.n_name, n_stats.unique_suppliers, n_stats.total_acctbal, o_summary.price_category
ORDER BY n.n_name;
