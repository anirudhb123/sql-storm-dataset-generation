
WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'O' AND oh.level < 5
),
SupplierAvailability AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price, COUNT(DISTINCT l.l_partkey) AS item_count
    FROM lineitem l
    WHERE l.l_shipdate >= '1996-01-01' AND l.l_shipdate <= '1996-12-31'
    GROUP BY l.l_orderkey
)
SELECT 
    oh.o_orderkey,
    oh.o_orderdate,
    os.total_price,
    sa.total_available,
    oh.level, 
    CASE WHEN sa.total_available IS NULL THEN 'Out of Stock' ELSE 'In Stock' END AS availability_status,
    CONCAT('Order ', oh.o_orderkey, ' of date ', oh.o_orderdate) AS order_description
FROM OrderHierarchy oh
LEFT JOIN OrderSummary os ON oh.o_orderkey = os.l_orderkey
LEFT JOIN SupplierAvailability sa ON os.item_count = sa.ps_partkey
WHERE os.total_price > 1000 AND oh.o_orderdate < '1998-10-01'
ORDER BY oh.o_orderdate DESC, oh.o_orderkey;
