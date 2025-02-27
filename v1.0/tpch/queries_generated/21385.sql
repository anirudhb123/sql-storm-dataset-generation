WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM RankedSuppliers s
    WHERE s.rnk <= 5
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           CASE 
               WHEN l.l_discount > 0.2 THEN 'High Discount'
               ELSE 'Regular Discount'
           END AS discount_category
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate IS NOT NULL AND l.l_returnflag = 'N'
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    WHERE ps.ps_supplycost = (SELECT MAX(ps2.ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_partkey = ps.ps_partkey)
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT DISTINCT 
    p.p_name, 
    CONCAT('Total Orders: ', COUNT(DISTINCT od.o_orderkey)) AS order_summary,
    COALESCE(SUM(CASE WHEN od.discount_category = 'High Discount' THEN od.o_totalprice END), 0) AS total_high_discount_sales,
    COALESCE(SUM(CASE WHEN od.discount_category = 'Regular Discount' THEN od.o_totalprice END), 0) AS total_regular_discount_sales
FROM part p
LEFT JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN TopSuppliers ts ON sp.ps_suppkey = ts.s_suppkey
LEFT JOIN OrderDetails od ON od.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
GROUP BY p.p_name
HAVING SUM(sp.total_avail_qty) IS NOT NULL AND SUM(sp.total_avail_qty) > 10
ORDER BY total_high_discount_sales DESC, p.p_name
FETCH FIRST 10 ROWS ONLY;
