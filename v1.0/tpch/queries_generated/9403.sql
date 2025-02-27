WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATEADD(month, -6, GETDATE())
),
AggregateData AS (
    SELECT ro.o_orderkey, ro.o_totalprice, ro.o_orderdate, n.n_name AS nation_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, COUNT(DISTINCT ro.o_custkey) AS unique_customers
    FROM RecentOrders ro
    JOIN lineitem l ON ro.o_orderkey = l.l_orderkey
    JOIN nation n ON ro.c_nationkey = n.n_nationkey
    GROUP BY ro.o_orderkey, ro.o_totalprice, ro.o_orderdate, n.n_name
)
SELECT ad.nation_name, AVG(ad.revenue) AS avg_revenue, COUNT(ad.o_orderkey) AS total_orders,
       (SELECT COUNT(DISTINCT s.s_suppkey)
        FROM RankedSuppliers rs
        WHERE rs.rank <= 5 AND rs.s_nationkey = ad.nation_name) AS top_suppliers_count
FROM AggregateData ad
GROUP BY ad.nation_name
ORDER BY avg_revenue DESC;
