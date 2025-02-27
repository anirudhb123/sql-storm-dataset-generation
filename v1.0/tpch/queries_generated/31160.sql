WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.level < 5
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           RANK() OVER (ORDER BY c.c_acctbal DESC) AS rnk
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
part_supplier_details AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_availqty) AS total_available_quantity,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
line_item_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2023-01-01'
    GROUP BY l.l_orderkey
)
SELECT 
    rh.r_name,
    tc.c_name AS top_customer_name,
    pDetails.p_name,
    pDetails.supplier_count,
    pDetails.total_available_quantity,
    pDetails.total_supply_cost,
    SUM(COALESCE(lis.revenue, 0)) AS total_revenue
FROM region rh
JOIN nation n ON rh.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
JOIN top_customers tc ON c.c_custkey = tc.c_custkey
LEFT JOIN part_supplier_details pDetails ON pDetails.supplier_count > 2
LEFT JOIN line_item_summary lis ON lis.l_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_orderstatus = 'O'
) 
GROUP BY rh.r_name, tc.c_name, pDetails.p_name, pDetails.supplier_count, pDetails.total_available_quantity, pDetails.total_supply_cost
HAVING SUM(lis.revenue) > 1000000
ORDER BY total_revenue DESC;
