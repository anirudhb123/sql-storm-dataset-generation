WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
RankedSuppliers AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY TotalCost DESC) as Rank
    FROM TopSuppliers
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice,
        RANK() OVER (ORDER BY o.o_orderdate DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
OrderDetails AS (
    SELECT lo.l_orderkey, lo.l_partkey, lo.l_quantity, lo.l_extendedprice,
        lo.l_discount, lo.l_tax, lo.l_shipdate,
        (lo.l_extendedprice * (1 - lo.l_discount)) AS NetRevenue
    FROM lineitem lo
    JOIN RecentOrders ro ON lo.l_orderkey = ro.o_orderkey
)
SELECT n.n_name AS Nation, 
       COUNT(DISTINCT os.s_suppkey) AS SupplierCount,
       SUM(od.NetRevenue) AS TotalRevenue,
       AVG(od.l_quantity) AS AvgQuantity,
       MAX(od.l_shipdate) AS LastShipDate
FROM OrderDetails od
JOIN supplier s ON od.l_partkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN RankedSuppliers rs ON s.s_nationkey = rs.s_nationkey
GROUP BY n.n_name
HAVING SUM(od.NetRevenue) > 50000
ORDER BY TotalRevenue DESC
LIMIT 10;
