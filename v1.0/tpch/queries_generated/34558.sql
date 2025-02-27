WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN supplier_hierarchy sh ON ps.ps_partkey = sh.s_suppkey
),
aggregated_lineitems AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(*) AS item_count,
           AVG(l.l_tax) AS avg_tax
    FROM lineitem l
    WHERE l.l_returnflag = 'R'
    GROUP BY l.l_orderkey
),
customer_order_summary AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
ranked_orders AS (
    SELECT c.c_name, 
           o.o_orderkey,
           o.o_orderdate,
           RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
)
SELECT s.s_name,
       r.r_name,
       SUM(al.total_revenue) AS total_lineitem_revenue,
       COUNT(DISTINCT co.c_custkey) AS unique_customers,
       MAX(co.total_spent) AS highest_spender,
       MIN(co.total_spent) AS lowest_spender
FROM supplier s
JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN aggregated_lineitems al ON al.l_orderkey = l.l_orderkey
JOIN customer_order_summary co ON co.total_orders > 5
WHERE l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
GROUP BY s.s_name, r.r_name
HAVING AVG(al.avg_tax) < 0.1
ORDER BY total_lineitem_revenue DESC;
