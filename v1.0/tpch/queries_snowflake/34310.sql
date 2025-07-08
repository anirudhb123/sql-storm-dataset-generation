
WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
    ORDER BY total_cost DESC
    LIMIT 5
), RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) as rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '1998-10-01'::DATE - INTERVAL '1 month'
), SupplierStats AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING AVG(ps.ps_supplycost) IS NOT NULL
)
SELECT r.r_name, SUM(so.total_cost) AS total_supply_cost, SUM(ro.o_totalprice) AS total_order_value
FROM region r
LEFT JOIN (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    HAVING s.s_suppkey IN (SELECT s_suppkey FROM TopSuppliers)
) so ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = 
    (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = so.s_suppkey LIMIT 1))
LEFT JOIN RecentOrders ro ON ro.rn < 3
WHERE so.total_cost IS NOT NULL
GROUP BY r.r_name
ORDER BY total_supply_cost DESC, total_order_value DESC
LIMIT 10;
