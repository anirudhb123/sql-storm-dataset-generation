WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS hierarchy_level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.hierarchy_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
),
SupplierStats AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_availqty,
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
CustomerOrderCounts AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY c.c_custkey
),
LineItemStats AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(*) AS line_item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    c.c_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    oh.hierarchy_level,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(li.net_revenue) AS total_revenue,
    COUNT(DISTINCT li.line_item_count) AS total_line_items,
    CASE 
        WHEN c.c_acctbal IS NULL THEN 'No Balance'
        ELSE CONCAT('Balance: $', CAST(c.c_acctbal AS VARCHAR))
    END AS customer_balance_status,
    ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(li.net_revenue) DESC) AS rank_within_nation
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
LEFT JOIN lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN SupplierStats s ON li.l_partkey = s.ps_partkey
WHERE c.c_mktsegment = 'BUILDING'
GROUP BY c.c_name, s.s_name, oh.hierarchy_level, c.c_acctbal
HAVING SUM(li.net_revenue) > 10000
ORDER BY total_revenue DESC
LIMIT 50;
