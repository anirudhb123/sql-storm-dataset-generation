WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_name = 'NATION_A'  -- Start from a specific nation

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_availability AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, 
           LEAST(ps.ps_supplycost, 100.00) AS effective_cost,
           CASE 
               WHEN ps.ps_availqty IS NULL THEN 0
               WHEN ps.ps_availqty < 50 THEN 'LOW'
               ELSE 'HIGH' 
           END AS availability
    FROM partsupp ps
    WHERE ps.ps_availqty IS NOT NULL
),
part_supplier_info AS (
    SELECT p.p_partkey, p.p_name, s.s_name, sa.effective_cost, sa.availability
    FROM part p
    JOIN supplier s ON p.p_partkey = s.s_nationkey
    LEFT JOIN supplier_availability sa ON p.p_partkey = sa.ps_partkey
),
customer_order_stats AS (
    SELECT c.c_custkey, c.c_name, AVG(o.o_totalprice) AS avg_order_value,
           COUNT(o.o_orderkey) AS total_orders,
           FIRST_VALUE(o.o_orderdate) OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate) AS first_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
filtered_orders AS (
    SELECT DISTINCT o.o_orderkey, c.c_custkey, c.c_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE c.c_acctbal > 1000.00 
    AND o.o_orderstatus IN ('F', 'O')
)
SELECT nh.n_name AS nation_name, 
       COUNT(DISTINCT psi.p_partkey) AS unique_parts,
       SUM(CASE WHEN psi.availability = 'HIGH' THEN 1 ELSE 0 END) AS high_availability_parts,
       AVG(cos.avg_order_value) AS average_customer_order_value,
       MAX(cos.total_orders) AS max_orders_by_customer
FROM nation_hierarchy nh
LEFT JOIN part_supplier_info psi ON nh.n_nationkey = psi.s_name
LEFT JOIN customer_order_stats cos ON nh.n_nationkey = cos.c_custkey
WHERE nh.level > 0
GROUP BY nh.n_name
HAVING COUNT(DISTINCT psi.p_partkey) > 0
ORDER BY average_customer_order_value DESC NULLS LAST;
