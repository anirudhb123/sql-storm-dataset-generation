WITH SupplierTotals AS (
    SELECT ps.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM partsupp ps
    GROUP BY ps.s_suppkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, ci.total_order_value
    FROM orders o
    LEFT JOIN (
        SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
        FROM lineitem l
        WHERE l.l_returnflag = 'N'
        GROUP BY l.l_orderkey
    ) ci ON o.o_orderkey = ci.l_orderkey
),
NationSupplier AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    r.r_name AS region,
    ns.n_name AS nation,
    ns.supplier_count,
    COUNT(DISTINCT od.o_orderkey) AS total_orders,
    COALESCE(SUM(od.o_totalprice), 0) AS total_revenue,
    MAX(st.total_value) AS max_supplier_value
FROM region r
JOIN nation ns ON ns.n_regionkey = r.r_regionkey
LEFT JOIN NationSupplier ns ON ns.n_nationkey = ns.n_nationkey
LEFT JOIN OrderDetails od ON od.total_order_value > 10000
LEFT JOIN SupplierTotals st ON st.s_suppkey IN (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 30))
WHERE ns.supplier_count > 0 OR od.o_orderkey IS NULL
GROUP BY r.r_name, ns.n_name, ns.supplier_count
ORDER BY total_revenue DESC, max_supplier_value DESC;
