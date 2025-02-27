WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
PartInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 50
), 
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, l.l_quantity, l.l_extendedprice, l.l_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
), 
FinalSummary AS (
    SELECT 
        si.nation_name, 
        COUNT(DISTINCT od.o_orderkey) AS total_orders,
        SUM(od.o_totalprice) AS total_revenue,
        SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_sales,
        AVG(si.s_acctbal) AS avg_supplier_acctbal
    FROM SupplierInfo si
    JOIN OrderDetails od ON si.s_suppkey IN (
        SELECT ps_suppkey 
        FROM partsupp 
        WHERE ps_partkey IN (SELECT p_partkey FROM PartInfo)
    )
    GROUP BY si.nation_name
)

SELECT nation_name, total_orders, total_revenue, total_sales, avg_supplier_acctbal
FROM FinalSummary
ORDER BY total_sales DESC
LIMIT 10;
