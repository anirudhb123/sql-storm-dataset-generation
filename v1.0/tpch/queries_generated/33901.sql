WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_container, p_retailprice, p_comment
    FROM part
    WHERE p_size > 10

    UNION ALL

    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
    FROM part p
    JOIN part_hierarchy ph ON ph.p_partkey = p.p_partkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available,
    SUM(ph.p_retailprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_extendedprice) OVER (PARTITION BY n.n_nationkey ORDER BY l.l_shipdate) AS avg_extended_price,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Volume'
        WHEN SUM(l.l_quantity) BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    STRING_AGG(DISTINCT l.l_shipmode) AS shipping_modes,
    p.product_type AS product_type
FROM supplier s
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN (
    SELECT DISTINCT p_type AS product_type
    FROM part_hierarchy
) AS p ON p.product_type = l.l_shipmode
GROUP BY n.n_name, p.product_type
HAVING SUM(ps.ps_availqty IS NOT NULL) > 0
ORDER BY total_revenue DESC
LIMIT 10;
