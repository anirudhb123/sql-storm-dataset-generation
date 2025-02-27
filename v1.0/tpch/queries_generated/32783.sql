WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 
           1 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 
           nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal > 1000
),
most_expensive_parts AS (
    SELECT ps.ps_partkey, MAX(ps.ps_supplycost) AS max_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
customer_order_summary AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
order_line_details AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM lineitem l
    WHERE l.l_shipdate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY l.l_orderkey
)

SELECT n.n_name AS nation_name, 
       COALESCE(sd.s_name, 'No Supplier') AS supplier_name,
       COALESCE(cos.order_count, 0) AS total_orders,
       COALESCE(cos.total_spent, 0.00) AS total_spent,
       ol.total_line_value AS order_value_last_30_days,
       p.p_name AS part_name,
       CASE 
           WHEN mp.max_supplycost IS NULL THEN 'Not Supplied'
           ELSE 'Supplied'
       END AS supply_status
FROM nation_hierarchy n
LEFT JOIN supplier_details sd ON n.n_nationkey = sd.s_nationkey AND sd.rn = 1
LEFT JOIN customer_order_summary cos ON cos.c_custkey = sd.s_suppkey
LEFT JOIN order_line_details ol ON ol.l_orderkey = cos.c_custkey
LEFT JOIN most_expensive_parts mp ON mp.ps_partkey = ol.l_orderkey
LEFT JOIN part p ON p.p_partkey = mp.ps_partkey
WHERE n.level <= 3
ORDER BY n.n_name, total_spent DESC;
