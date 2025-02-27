WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey
    FROM nation
    WHERE n_nationkey = (SELECT MIN(n_nationkey) FROM nation)
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_regionkey
)
, part_supplier_summary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
)
, order_summary AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS total_orders,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' 
      AND o.o_orderdate < DATE '2023-10-01'
    GROUP BY o.o_custkey
)
SELECT r.r_name, nh.n_name, 
       ps.p_name, 
       COALESCE(pr.total_orders, 0) AS customer_orders, 
       COALESCE(ps.total_available_qty, 0) AS supplier_qty,
       ROUND(COALESCE(pr.total_revenue, 0), 2) AS customer_revenue,
       ROUND(COALESCE(ps.avg_supply_cost, 0), 2) AS average_supply_cost,
       CASE 
           WHEN COALESCE(pr.total_revenue, 0) > 10000 THEN 'High Revenue'
           WHEN COALESCE(pr.total_revenue, 0) BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
           ELSE 'Low Revenue'
       END AS revenue_category
FROM region r
LEFT JOIN nation_hierarchy nh ON r.r_regionkey = nh.n_regionkey
LEFT JOIN part_supplier_summary ps ON ps.ps_partkey = 
        (SELECT p.p_partkey 
         FROM part p 
         WHERE p.p_name LIKE '%Widget%'
         ORDER BY p.p_retailprice DESC
         LIMIT 1)
LEFT JOIN order_summary pr ON pr.o_custkey = 
        (SELECT c.c_custkey
         FROM customer c
         WHERE c.c_nationkey = nh.n_nationkey
         ORDER BY c.c_acctbal DESC
         LIMIT 1)
WHERE r.r_name IS NOT NULL
ORDER BY r.r_name, nh.n_name;
