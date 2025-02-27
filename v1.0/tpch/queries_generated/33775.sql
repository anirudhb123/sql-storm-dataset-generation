WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_address, s_nationkey, s_acctbal, 
           1 AS level, 
           CAST(s_name AS VARCHAR(255)) AS full_name
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'FRANCE')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, 
           h.level + 1, 
           CAST(CONCAT(h.full_name, ' -> ', s.s_name) AS VARCHAR(255))
    FROM supplier s
    JOIN supplier_hierarchy h ON s.s_nationkey = h.s_nationkey
    WHERE h.level < 5
),
total_orders AS (
    SELECT c.c_custkey,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
      AND o.o_orderdate >= DATE '2022-01-01'
    GROUP BY c.c_custkey
),
lineitem_summary AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(*) AS item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
ranked_orders AS (
    SELECT c.c_custkey,
           o.o_orderkey,
           RANK() OVER (PARTITION BY c.c_custkey ORDER BY total_revenue DESC) AS revenue_rank
    FROM customer c
    JOIN lineitem_summary los ON c.c_custkey = los.l_orderkey
    JOIN orders o ON los.l_orderkey = o.o_orderkey
)
SELECT r.level,
       s.s_name AS supplier_name,
       s.s_acctbal,
       t.total_spent,
       r.revenue_rank
FROM supplier_hierarchy s
LEFT JOIN total_orders t ON s.s_suppkey = t.c_custkey
LEFT JOIN ranked_orders r ON r.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = t.c_custkey)
WHERE s.s_acctbal IS NOT NULL
ORDER BY r.revenue_rank, s.s_name;
