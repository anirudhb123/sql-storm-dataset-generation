WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE sh.level < 5
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(lineitem.l_extendedprice) AS avg_extended_price,
    MAX(o.o_totalprice) AS max_order_price,
    MIN(o.o_orderdate) AS earliest_order_date,
    STRING_AGG(DISTINCT p.p_brand, ', ') AS unique_brands
FROM supplier_hierarchy sh
JOIN supplier s ON s.s_suppkey = sh.s_suppkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN part p ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem ON lineitem.l_suppkey = s.s_suppkey
JOIN orders o ON o.o_orderkey = lineitem.l_orderkey
JOIN nation n ON n.n_nationkey = s.s_nationkey
WHERE o.o_orderstatus IN ('O', 'F')
GROUP BY n.n_name
HAVING SUM(ps.ps_availqty) > 1000
ORDER BY supplier_count DESC, total_available_quantity DESC;
