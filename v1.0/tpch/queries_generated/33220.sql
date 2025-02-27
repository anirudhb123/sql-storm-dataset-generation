WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal < sh.s_acctbal
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS line_count,
        FIRST_VALUE(l.l_shipdate) OVER(PARTITION BY o.o_orderkey ORDER BY l.l_shipdate) AS first_ship_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(ps.ps_availqty, 0) AS available_quantity,
    SUM(os.total_sales) AS total_ordered_sales,
    s.s_name AS supplier_name,
    sh.level AS supplier_level
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN order_summary os ON l.l_orderkey = os.o_orderkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE p.p_retailprice > 100.00
  AND p.p_size IS NOT NULL
  AND (p.p_comment LIKE '%fragile%' OR p.p_comment IS NULL)
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, ps.ps_availqty, s.s_name, sh.level
HAVING SUM(os.total_sales) > 1000
ORDER BY total_ordered_sales DESC
LIMIT 50;
