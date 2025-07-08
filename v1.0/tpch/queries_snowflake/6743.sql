WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_acctbal,
           RANK() OVER(PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) AS rnk
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '1997-01-01'
), HighValueSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), LineitemAnalytics AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           SUM(l.l_quantity) AS total_quantity_sold
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1997-01-01'
    GROUP BY l.l_orderkey
)
SELECT ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.c_name, ro.c_acctbal,
       la.net_revenue, la.total_quantity_sold, hs.total_supply_cost
FROM RankedOrders ro
JOIN LineitemAnalytics la ON ro.o_orderkey = la.l_orderkey
JOIN HighValueSuppliers hs ON hs.ps_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    WHERE li.l_orderkey = ro.o_orderkey
)
WHERE ro.rnk = 1
ORDER BY ro.o_orderdate DESC, net_revenue DESC;