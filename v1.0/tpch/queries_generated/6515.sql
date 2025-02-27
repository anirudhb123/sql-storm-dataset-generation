WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RegionStats AS (
    SELECT n.n_regionkey, r.r_name, COUNT(DISTINCT c.c_custkey) AS total_customers, SUM(o.o_totalprice) AS total_orders
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_regionkey, r.r_name
),
OrderLineStats AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS line_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    r.r_name AS region,
    rs.s_name AS supplier,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(ols.total_revenue) AS total_revenue,
    rs.total_supply_cost
FROM RankedSuppliers rs
JOIN orderLineStats ols ON rs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem l ON ps.ps_partkey = l.l_partkey)
JOIN RegionStats r ON r.total_orders > 0
GROUP BY r.r_name, rs.s_name, rs.total_supply_cost
ORDER BY r.r_name, total_revenue DESC
LIMIT 10;
