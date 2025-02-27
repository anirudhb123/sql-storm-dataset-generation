WITH RECURSIVE price_increase AS (
    SELECT ps.partkey, 
           SUM(ps.ps_supplycost) AS total_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps.partkey ORDER BY ps.ps_supplycost DESC) AS rank_order
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.partkey
),
nation_log AS (
    SELECT n.n_nationkey, 
           n.n_name, 
           COUNT(*) AS order_count,
           SUM(o.o_totalprice) AS total_revenue
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
),
top_customers AS (
    SELECT c.c_custkey, 
           c.c_name, 
           ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 50000
),
flagged_orders AS (
    SELECT o.o_orderkey, 
           o.o_orderstatus,
           SUM(l.l_discount * l.l_extendedprice) AS discounted_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
    HAVING o.o_orderstatus = 'O' AND SUM(l.l_discount * l.l_extendedprice) > 1000
)
SELECT n.n_name, 
       nl.order_count, 
       nl.total_revenue, 
       tc.c_name AS top_customer,
       pi.partkey,
       pi.total_supplycost
FROM nation_log nl
JOIN top_customers tc ON nl.order_count > 10
JOIN price_increase pi ON nl.n_nationkey = pi.partkey
LEFT JOIN flagged_orders fo ON fo.o_orderkey = nl.order_count
WHERE nl.total_revenue IS NOT NULL
  AND nl.total_revenue > 20000
ORDER BY nl.total_revenue DESC, tc.customer_rank ASC
LIMIT 100;
