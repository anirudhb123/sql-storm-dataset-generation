WITH RecentOrders AS (
    SELECT o_orderkey, o_orderdate, o_totalprice, c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o_orderdate >= DATE '1997-01-01'
),
SupplierDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, s.s_name, s.s_acctbal
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 10000
),
LineItemDetails AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
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
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    COUNT(DISTINCT sd.ps_suppkey) AS supplier_count,
    SUM(l.total_revenue) AS total_revenue,
    tr.r_name AS top_region
FROM RecentOrders ro
JOIN SupplierDetails sd ON ro.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = sd.ps_partkey)
JOIN LineItemDetails l ON ro.o_orderkey = l.l_orderkey
CROSS JOIN TopRegions tr
GROUP BY ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, tr.r_name
HAVING SUM(l.total_revenue) > 50000
ORDER BY ro.o_orderdate DESC, total_revenue DESC;