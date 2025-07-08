WITH SupplierPart AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_brand = 'Brand#1' AND ps.ps_availqty > 0
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
SupplierRevenue AS (
    SELECT sp.s_suppkey, sp.s_name, od.o_orderstatus, SUM(od.total_revenue) AS revenue
    FROM SupplierPart sp
    JOIN OrderDetails od ON sp.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = od.o_orderkey LIMIT 1)
    GROUP BY sp.s_suppkey, sp.s_name, od.o_orderstatus
)
SELECT sr.s_name, sr.o_orderstatus, sr.revenue
FROM SupplierRevenue sr
WHERE sr.revenue > 10000
ORDER BY sr.revenue DESC;