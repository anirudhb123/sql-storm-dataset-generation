WITH RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_acctbal
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
), OrderLineItems AS (
    SELECT lo.l_orderkey, SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue, COUNT(*) AS item_count
    FROM lineitem lo
    JOIN RecentOrders ro ON lo.l_orderkey = ro.o_orderkey
    GROUP BY lo.l_orderkey
), SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT o.orderkey) AS total_orders,
    SUM(ol.total_revenue) AS total_revenue_generated,
    SUM(sp.total_available) AS total_parts_available
FROM RecentOrders ro
JOIN nation n ON ro.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN OrderLineItems ol ON ro.o_orderkey = ol.l_orderkey
LEFT JOIN SupplierParts sp ON sp.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey)
GROUP BY r.r_name, n.n_name
ORDER BY total_orders DESC, total_revenue_generated DESC;
