WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_nationkey, s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
  UNION ALL
    SELECT s.n_nationkey, sup.s_suppkey, sup.s_name, sup.s_acctbal, h.level + 1
    FROM supplier_hierarchy h
    JOIN supplier sup ON h.s_nationkey = sup.s_nationkey
    JOIN nation s ON sup.s_nationkey = s.n_nationkey
    WHERE sup.s_acctbal IS NOT NULL AND h.level < 5
),
order_summary AS (
    SELECT o.o_orderkey, o.o_totalprice, COUNT(l.l_orderkey) AS num_lineitems
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < CURRENT_DATE
    GROUP BY o.o_orderkey, o.o_totalprice
),
supply_summary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty, 
           AVG(ps.ps_supplycost) AS avg_supplycost, 
           STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
)
SELECT r.o_orderkey, r.o_totalprice, 
       COALESCE(s.total_availqty, 0) AS total_availqty, 
       COALESCE(s.avg_supplycost, 0) AS avg_supplycost, 
       h.s_name AS supplier_name,
       CASE 
           WHEN r.o_totalprice > 1000 THEN 'High'
           WHEN r.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium'
           ELSE 'Low' 
       END AS price_category
FROM ranked_orders r
LEFT JOIN supply_summary s ON r.o_orderkey = s.ps_partkey
LEFT JOIN supplier_hierarchy h ON r.o_orderkey = h.s_suppkey
WHERE r.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderstatus = 'F'
)
AND r.o_totalprice IS NOT NULL
ORDER BY r.o_totalprice DESC, h.level;
