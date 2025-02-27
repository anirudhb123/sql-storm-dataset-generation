WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.level < 5
), part_summary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
), high_revenue_orders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING total_revenue > (SELECT AVG(total_revenue) FROM (
        SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
        FROM lineitem
        GROUP BY l_orderkey
    ) AS average_revenue)
), customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    ps.total_avail_qty,
    ps.avg_supply_cost,
    coh.customer_count
FROM supplier_hierarchy s
JOIN part_summary ps ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
LEFT JOIN (SELECT c.c_custkey, COUNT(o.o_orderkey) AS customer_count 
           FROM customer_orders co 
           GROUP BY co.c_custkey) coh ON s.s_nationkey = coh.c_custkey
LEFT JOIN high_revenue_orders hro ON ps.p_partkey = hro.o_orderkey
WHERE ps.total_avail_qty > 50
ORDER BY ps.avg_supply_cost DESC, ps.total_avail_qty ASC
FETCH FIRST 10 ROWS ONLY;
