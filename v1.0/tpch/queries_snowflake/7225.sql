
WITH LatestOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_nationkey, o.o_orderstatus
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1996-01-01'
),
SupplierStats AS (
    SELECT ps.ps_partkey, s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT lo.l_orderkey, COUNT(lo.l_linenumber) AS item_count, SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
    FROM lineitem lo
    GROUP BY lo.l_orderkey
)
SELECT r.r_name, COUNT(DISTINCT lo.o_orderkey) AS order_count, SUM(ods.total_revenue) AS total_revenue, AVG(ss.avg_supplycost) AS avg_supplier_cost, SUM(ss.total_availqty) AS total_available_quantity
FROM LatestOrders lo
JOIN nation n ON n.n_nationkey = lo.c_nationkey
JOIN region r ON r.r_regionkey = n.n_regionkey
JOIN OrderDetails ods ON ods.l_orderkey = lo.o_orderkey
JOIN SupplierStats ss ON ss.ps_partkey IN (SELECT l_partkey FROM lineitem WHERE l_orderkey = lo.o_orderkey)
WHERE lo.o_orderstatus = 'F'
GROUP BY r.r_name
ORDER BY r.r_name;
