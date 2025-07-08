
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderstatus
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count, SUM(od.order_revenue) AS total_revenue
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN CustomerOrders od ON c.c_custkey = od.o_custkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.r_name, ns.n_name, ns.customer_count, ns.total_revenue, sd.total_cost
FROM region r
JOIN NationStats ns ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = ns.n_nationkey)
JOIN SupplierDetails sd ON ns.n_nationkey = sd.s_nationkey
ORDER BY ns.total_revenue DESC, sd.total_cost ASC
LIMIT 10;
