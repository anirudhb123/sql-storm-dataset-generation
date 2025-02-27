WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal < 1000 AND sh.level < 5
),

order_summary AS (
    SELECT o.o_orderkey, o.o_totalprice,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem,
           RANK() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31' 
    GROUP BY o.o_orderkey, o.o_totalprice
),

top_orders AS (
    SELECT os.*, 
           CASE 
               WHEN os.total_lineitem IS NULL THEN 'No Line Items' 
               ELSE 'Has Line Items' 
           END AS lineitem_status 
    FROM order_summary os
    WHERE os.order_rank = 1 
),

supplier_order_summary AS (
    SELECT sh.s_name, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_order_value
    FROM supplier_hierarchy sh
    LEFT JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY sh.s_name
)

SELECT t.o_orderkey, 
       t.total_lineitem, 
       CASE 
           WHEN s.total_orders > 5 THEN 'High Supplier Activity' 
           ELSE 'Low Supplier Activity' 
       END AS supplier_activity,
       COALESCE(s.total_order_value, 0) AS supplier_order_value
FROM top_orders t
LEFT JOIN supplier_order_summary s ON t.o_orderkey = s.total_orders
ORDER BY t.total_lineitem DESC, supplier_activity;
