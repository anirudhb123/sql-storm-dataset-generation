WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
OrderDetails AS (
    SELECT ro.o_orderkey, COUNT(li.l_linenumber) AS line_item_count, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM RankedOrders ro
    JOIN lineitem li ON ro.o_orderkey = li.l_orderkey
    WHERE ro.rank <= 10
    GROUP BY ro.o_orderkey
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available_quantity
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
SupplierRegion AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    od.o_orderkey,
    od.line_item_count,
    od.total_revenue,
    sr.s_name,
    sr.nation_name,
    sr.region_name,
    ps.total_available_quantity
FROM OrderDetails od
JOIN SupplierRegion sr ON sr.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM PartSupplier ps
    WHERE ps.ps_partkey IN (
        SELECT l.l_partkey
        FROM lineitem l
        WHERE l.l_orderkey = od.o_orderkey
    )
)
JOIN PartSupplier ps ON ps.ps_suppkey = sr.s_suppkey
ORDER BY od.total_revenue DESC, od.o_orderkey;
