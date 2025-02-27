WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 0 AS depth
    FROM orders o
    WHERE o.o_orderdate < DATE '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.depth + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.depth < 2
), 
SupplierSummary AS (
    SELECT s.s_suppkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
), 
OrderTotal AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), 
RegionSupplier AS (
    SELECT 
        r.r_name,
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM region r
    INNER JOIN nation n ON n.n_regionkey = r.r_regionkey
    INNER JOIN supplier s ON s.s_nationkey = n.n_nationkey
    LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
    GROUP BY r.r_name, s.s_suppkey
)
SELECT 
    oh.o_orderkey,
    oh.o_orderdate,
    oh.o_totalprice,
    oss.total_spent,
    oss.order_count,
    rss.r_name,
    rss.part_count,
    ss.total_avail_qty,
    ss.avg_supply_cost,
    CASE 
        WHEN oss.total_spent IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    STRING_AGG(DISTINCT CONCAT('Part Key: ', ps.ps_partkey, ' | Quantity: ', ps.ps_availqty), '; ') AS part_details
FROM OrderHierarchy oh
LEFT JOIN OrderTotal oss ON oh.o_orderkey = oss.c_custkey
LEFT JOIN RegionSupplier rss ON rss.s_suppkey = oss.c_custkey
LEFT JOIN SupplierSummary ss ON ss.s_suppkey = rss.s_suppkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = ss.s_suppkey 
WHERE oh.o_totalprice > 1000
GROUP BY oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, oss.total_spent, oss.order_count, rss.r_name, rss.part_count, ss.total_avail_qty, ss.avg_supply_cost
ORDER BY oh.o_orderdate DESC, oh.o_orderkey;
