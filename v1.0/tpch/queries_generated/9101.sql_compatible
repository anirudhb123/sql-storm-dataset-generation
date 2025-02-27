
WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_value DESC
    LIMIT 10
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_custkey
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
OrderLineItems AS (
    SELECT l.l_orderkey, l.l_quantity, l.l_extendedprice, l.l_discount, l.l_tax, l.l_shipdate
    FROM lineitem l
    JOIN RecentOrders ro ON l.l_orderkey = ro.o_orderkey
),
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey
    FROM customer c
    JOIN RecentOrders ro ON c.c_custkey = ro.o_custkey
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    ORDER BY nation_count DESC
    LIMIT 5
)
SELECT 
    cs.c_name AS customer_name,
    ts.s_name AS supplier_name,
    SUM(oli.l_extendedprice * (1 - oli.l_discount)) AS total_revenue,
    r.r_name AS region_name,
    COUNT(DISTINCT oli.l_orderkey) AS total_orders
FROM OrderLineItems oli
JOIN TopSuppliers ts ON oli.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = ts.s_suppkey)
JOIN CustomerDetails cs ON oli.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
JOIN TopRegions r ON cs.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
GROUP BY cs.c_name, ts.s_name, r.r_name
HAVING SUM(oli.l_extendedprice * (1 - oli.l_discount)) > 50000
ORDER BY total_revenue DESC;
