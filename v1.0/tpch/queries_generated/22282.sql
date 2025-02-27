WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE '%East%')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
part_supplier_stats AS (
    SELECT p.p_partkey, COUNT(ps.ps_suppkey) AS supplier_count, 
           SUM(ps.ps_availqty) AS total_available_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey 
    GROUP BY p.p_partkey
),
order_summary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT n.n_name, ps.supplier_count, ps.total_available_qty, ps.avg_supply_cost,
       COALESCE(o.total_revenue, 0) AS customer_revenue,
       CASE WHEN ps.total_available_qty IS NULL THEN 'NULL' ELSE 'NOT NULL' END AS quantity_status
FROM nation_hierarchy n
LEFT JOIN part_supplier_stats ps ON n.n_nationkey = ps.p_partkey
FULL OUTER JOIN order_summary o ON n.n_nationkey = o.o_custkey
WHERE (ps.avg_supply_cost IS NOT NULL AND ps.supplier_count > 1)
   OR (o.total_revenue IS NULL AND n.n_name LIKE '%land%')
ORDER BY total_available_qty DESC NULLS LAST, customer_revenue DESC;
