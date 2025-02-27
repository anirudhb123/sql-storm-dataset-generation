WITH RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATEADD(year, -1, GETDATE())
),
SupplierCosts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * l.l_quantity) AS total_cost
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY ps.ps_partkey
),
AggregatedData AS (
    SELECT r.r_name AS region, n.n_name AS nation, SUM(rc.total_cost) AS total_supplier_cost
    FROM RecentOrders ro
    JOIN nation n ON ro.o_custkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN SupplierCosts rc ON ro.o_orderkey = rc.ps_partkey
    GROUP BY r.r_name, n.n_name
)
SELECT region, nation, total_supplier_cost
FROM AggregatedData
ORDER BY total_supplier_cost DESC
LIMIT 100;
