WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
), 
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), 
order_summary AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
ranked_orders AS (
    SELECT os.o_orderkey, os.o_orderstatus, os.total_price,
           RANK() OVER (PARTITION BY os.o_orderstatus ORDER BY os.total_price DESC) AS order_rank
    FROM order_summary os
)
SELECT n.n_name, s.s_name, ro.o_orderkey, ro.total_price
FROM ranked_orders ro
JOIN supplier_info s ON ro.total_price > (SELECT AVG(total_cost) FROM supplier_info WHERE s_nationkey = s.s_nationkey)
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE n.n_name IS NOT NULL
ORDER BY n.n_name, ro.total_price DESC
LIMIT 100;