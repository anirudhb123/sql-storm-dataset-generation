
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 
           CAST(s_name AS VARCHAR) AS path
    FROM supplier
    WHERE s_acctbal > 100000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CONCAT(sh.path, ' -> ', s.s_name)
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
customer_order_summary AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_nationkey
),
region_statistics AS (
    SELECT n.n_regionkey, r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_regionkey, r.r_name
)
SELECT rh.path AS supplier_path, 
       cos.total_orders, cos.total_spent,
       r_stats.supplier_count, r_stats.total_supply_cost
FROM supplier_hierarchy rh
JOIN customer_order_summary cos ON rh.s_nationkey = cos.c_custkey
JOIN region_statistics r_stats ON r_stats.n_regionkey = rh.s_nationkey
WHERE cos.order_rank <= 10
AND rh.s_acctbal BETWEEN 100000 AND 500000
ORDER BY r_stats.total_supply_cost DESC, cos.total_spent DESC;
