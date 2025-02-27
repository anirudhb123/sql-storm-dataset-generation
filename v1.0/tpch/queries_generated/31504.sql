WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, l.l_partkey, l.l_quantity, l.l_extendedprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_order
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
),
AggSupplierStats AS (
    SELECT ps.s_suppkey, SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.s_suppkey
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
LastOrders AS (
    SELECT o.o_orderkey, MAX(o.o_orderdate) AS last_order_date
    FROM orders o
    GROUP BY o.o_orderkey
),
FilteredOrders AS (
    SELECT oh.o_orderkey, oh.o_orderdate, oh.l_partkey, oh.l_quantity, oh.l_extendedprice
    FROM OrderHierarchy oh
    JOIN LastOrders lo ON oh.o_orderkey = lo.o_orderkey
)
SELECT fo.o_orderkey, fo.o_orderdate, f.name AS part_name, 
       COALESCE(s.total_avail_qty, 0) AS supplier_avail_qty,
       COALESCE(s.avg_supply_cost, 0.00) AS avg_supply_cost,
       fo.l_quantity, fo.l_extendedprice, 
       CASE 
           WHEN fo.l_quantity > 100 THEN 'High Volume'
           ELSE 'Standard Volume'
       END AS volume_category
FROM FilteredOrders fo
LEFT JOIN HighValueParts f ON fo.l_partkey = f.p_partkey 
LEFT JOIN AggSupplierStats s ON f.p_brand = s.s_suppkey
WHERE fo.o_orderdate >= DATE '2023-01-01'
ORDER BY fo.o_orderdate DESC, f.price_rank;
