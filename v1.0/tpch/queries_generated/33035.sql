WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
order_summary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_custkey) AS customer_count,
           MAX(l.l_shipdate) AS last_ship_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey
),
part_supplier AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(ps.ps_availqty) AS total_available_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT n.n_name, 
       rs.total_revenue,
       CASE WHEN rs.customer_count > 0 THEN (rs.total_revenue / rs.customer_count) ELSE 0 END AS revenue_per_customer,
       ps.total_available_qty,
       ps.avg_supply_cost,
       (SELECT COUNT(*) FROM supplier_hierarchy sh WHERE sh.nationkey = n.n_nationkey) AS supplier_count
FROM nation n
LEFT JOIN order_summary rs ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = rs.o_orderkey)
LEFT JOIN part_supplier ps ON ps.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = rs.o_orderkey LIMIT 1)
WHERE n.n_comment IS NOT NULL
ORDER BY ps.avg_supply_cost DESC, rs.total_revenue DESC;
