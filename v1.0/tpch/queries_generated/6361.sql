WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), NationData AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, n.n_name AS customer_nation
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN NationData n ON c.c_nationkey = n.n_nationkey
), OrderLineDetails AS (
    SELECT co.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, COUNT(l.l_orderkey) AS total_lines
    FROM CustomerOrders co
    JOIN lineitem l ON co.o_orderkey = l.l_orderkey
    GROUP BY co.o_orderkey
)
SELECT ns.n_name, COUNT(DISTINCT co.c_custkey) AS total_customers, SUM(ol.revenue) AS total_revenue, AVG(ol.total_lines) AS avg_lines_per_order
FROM NationData ns
JOIN CustomerOrders co ON ns.n_nationkey = co.customer_nation
JOIN OrderLineDetails ol ON co.o_orderkey = ol.o_orderkey
JOIN RankedSuppliers rs ON co.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = rs.s_suppkey)
GROUP BY ns.n_name
ORDER BY total_revenue DESC;
