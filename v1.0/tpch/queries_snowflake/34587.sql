WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name,
           COUNT(s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
final_report AS (
    SELECT nh.n_name, nh.supplier_count, nh.avg_acctbal,
           ps.total_cost,
           CASE 
               WHEN ps.total_cost IS NULL THEN 'No Parts'
               ELSE 'Parts Available'
           END AS availability
    FROM nation_summary nh
    LEFT JOIN part_supplier ps ON nh.n_nationkey = ps.p_partkey
)
SELECT fr.n_name, fr.supplier_count, fr.avg_acctbal, fr.total_cost, fr.availability,
       ROW_NUMBER() OVER (ORDER BY fr.avg_acctbal DESC) AS country_rank,
       (SELECT COUNT(*) FROM orders WHERE o_orderdate > '1997-01-01' AND o_totalprice > 5000) AS recent_large_orders
FROM final_report fr
WHERE fr.avg_acctbal IS NOT NULL
ORDER BY fr.total_cost DESC;