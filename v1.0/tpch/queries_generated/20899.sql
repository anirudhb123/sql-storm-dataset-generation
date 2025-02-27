WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 2
),
NationCounts AS (
    SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS cust_count
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_name
),
PartMetrics AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(p.p_retailprice) AS avg_price
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
OrderInfo AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
)
SELECT
    ph.s_name AS Supplier_Name,
    nc.n_name AS Nation_Name,
    pm.total_avail_qty AS Total_Available_Quantity,
    pm.avg_price AS Average_Part_Price,
    oi.total_line_price AS Total_Line_Item_Price,
    oi.o_totalprice - oi.total_line_price AS Profit_Margin,
    COUNT(DISTINCT oi.o_orderkey) FILTER (WHERE oi.o_totalprice > 10000) AS High_Value_Orders
FROM SupplierHierarchy ph
JOIN Nation n ON ph.s_nationkey = n.n_nationkey
JOIN NationCounts nc ON n.n_name = nc.n_name
JOIN PartMetrics pm ON pm.total_avail_qty > (SELECT AVG(total_avail_qty) FROM PartMetrics)
LEFT JOIN OrderInfo oi ON oi.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderstatus = 'F'
    AND EXISTS (
        SELECT 1
        FROM lineitem l
        WHERE l.l_orderkey = o.o_orderkey AND l.l_discount > 0.1
    )
)
GROUP BY ph.s_name, nc.n_name, pm.total_avail_qty, pm.avg_price, oi.total_line_price, oi.o_totalprice
ORDER BY Total_Available_Quantity DESC, Average_Part_Price ASC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
