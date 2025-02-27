WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal < (SELECT AVG(s_acctbal) * (1 + 0.1 * sh.level) FROM supplier)
),

order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),

customer_summary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),

joined_data AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, 
           r.r_name AS region_name, n.n_name AS nation_name, 
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, r.r_name, n.n_name
),

final_summary AS (
    SELECT j.*, 
           ROW_NUMBER() OVER (PARTITION BY j.region_name ORDER BY j.total_returned DESC) AS rank_within_region 
    FROM joined_data j
)

SELECT f.*, 
       CASE 
           WHEN f.order_count > 50 THEN 'High Volume' 
           WHEN f.order_count > 20 THEN 'Medium Volume' 
           ELSE 'Low Volume' 
       END AS order_volume_category,
       sh.level AS supplier_level
FROM final_summary f
LEFT JOIN supplier_hierarchy sh ON f.p_partkey = sh.s_suppkey
WHERE f.total_returned IS NOT NULL
ORDER BY f.region_name, f.rank_within_region;
