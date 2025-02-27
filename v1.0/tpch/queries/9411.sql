
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    ORDER BY nation_count DESC
    LIMIT 5
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
),
FinalReport AS (
    SELECT 
        ro.o_orderkey,
        ro.o_totalprice,
        rs.s_name,
        tr.r_name,
        rs.total_supply_cost
    FROM RecentOrders ro
    JOIN lineitem li ON ro.o_orderkey = li.l_orderkey
    JOIN RankedSuppliers rs ON li.l_suppkey = rs.s_suppkey
    JOIN customer c ON ro.o_custkey = c.c_custkey
    JOIN TopRegions tr ON c.c_nationkey = (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_regionkey = tr.r_regionkey 
        LIMIT 1
    )
    ORDER BY ro.o_totalprice DESC
)
SELECT * FROM FinalReport
WHERE total_supply_cost > 10000
ORDER BY o_totalprice DESC;
