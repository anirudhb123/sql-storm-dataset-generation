WITH SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, l.l_partkey, l.l_quantity, l.l_extendedprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_num
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
),
CustomerRegion AS (
    SELECT c.c_custkey, c.c_name, n.n_regionkey, r.r_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT cr.r_name AS region, ss.s_name AS supplier_name, SUM(od.l_extendedprice) AS total_revenue,
       COUNT(DISTINCT od.o_orderkey) AS total_orders,
       ROUND(SUM(od.l_extendedprice) / COUNT(DISTINCT od.o_orderkey), 2) AS avg_order_value,
       STRING_AGG(CASE WHEN od.line_num = 1 THEN CONCAT('PartKey: ', od.l_partkey, ' Qty: ', od.l_quantity) END, '; ') AS first_lineitem_details
FROM CustomerRegion cr
LEFT JOIN OrderDetails od ON cr.c_custkey = od.o_custkey
LEFT JOIN SupplierSummary ss ON od.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ss.s_suppkey)
WHERE cr.r_name IS NOT NULL AND od.l_quantity > 0
GROUP BY cr.r_name, ss.s_name
ORDER BY total_revenue DESC, region ASC;
