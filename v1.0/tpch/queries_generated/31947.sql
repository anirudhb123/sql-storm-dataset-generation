WITH RECURSIVE supplier_hierarchy AS (
    SELECT s1.s_suppkey, s1.s_name, s1.s_nationkey, 1 AS level
    FROM supplier s1
    WHERE s1.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL

    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s2 ON s2.s_nationkey = sh.s_nationkey
    WHERE s2.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    AND sh.level < 5
),
lowest_activity_orders AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS item_count
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
    HAVING COUNT(l.l_orderkey) < 5
),
aggregate_results AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_returnflag = 'N'
    GROUP BY ps.ps_partkey
)
SELECT DISTINCT
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COALESCE(a.avg_price_after_discount, 0) AS average_price_discounted,
    COALESCE(b.item_count, 0) AS order_count
FROM part p
LEFT JOIN aggregate_results a ON p.p_partkey = a.ps_partkey
LEFT JOIN supplier_hierarchy s ON s.s_nationkey = p.p_partkey
LEFT JOIN nation n ON n.n_nationkey = s.s_nationkey
LEFT JOIN region r ON r.r_regionkey = n.n_regionkey
LEFT JOIN lowest_activity_orders b ON b.o_orderkey = s.s_suppkey
WHERE (a.supplier_count IS NOT NULL OR b.item_count IS NULL)
AND (p.p_size > 10 OR p.p_mfgr LIKE 'Manufacturer%')
ORDER BY average_price_discounted DESC, supplier_name;
