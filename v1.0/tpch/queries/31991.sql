WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_custkey, 1 AS depth
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_custkey, oh.depth + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey 
    WHERE o.o_orderdate > oh.o_orderdate AND o.o_orderstatus = 'O'
),
SupplierStats AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
LineItemStats AS (
    SELECT l.l_orderkey, 
           COUNT(l.l_linenumber) AS line_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    WHERE l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '30 DAY'
    GROUP BY l.l_orderkey
)
SELECT 
    c.c_name, 
    COALESCE(r.r_name, 'Unknown') AS region,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(ls.total_price) AS total_order_value,
    AVG(os.total_supply_value) AS avg_supply_value,
    MAX(CASE WHEN ls.line_count > 5 THEN 'High Volume' ELSE 'Normal Volume' END) AS volume_category
FROM customer c
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN LineItemStats ls ON o.o_orderkey = ls.l_orderkey
LEFT JOIN SupplierStats os ON ls.line_count = os.ps_suppkey
WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
GROUP BY c.c_name, r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_order_value DESC, order_count DESC;