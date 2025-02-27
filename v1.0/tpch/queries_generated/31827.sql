WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_name ILIKE 'A%'
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY c.c_custkey
),
lineitem_details AS (
    SELECT l.l_orderkey, COUNT(*) OVER (PARTITION BY l.l_orderkey) AS item_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales_revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31' 
          AND l.l_returnflag = 'N'
)
SELECT n.n_name AS nation_name, 
       SUM(cs.total_spent) AS total_customer_spent, 
       SUM(ss.total_cost) AS total_supplier_cost,
       AVG(ld.item_count) AS avg_items_per_order,
       MAX(ld.sales_revenue) AS max_sales_per_order
FROM nation_hierarchy n
LEFT JOIN customer_orders cs ON cs.c_custkey = n.n_nationkey
LEFT JOIN supplier_summary ss ON ss.s_suppkey = n.n_nationkey
LEFT JOIN lineitem_details ld ON ld.l_orderkey = cs.c_custkey
GROUP BY n.n_name
HAVING SUM(cs.total_spent) IS NOT NULL OR SUM(ss.total_cost) IS NOT NULL
ORDER BY total_customer_spent DESC, nation_name ASC;
