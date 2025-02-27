WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_container, p_retailprice, p_comment, 0 AS level
    FROM part
    WHERE p_size < 20
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment, ph.level + 1
    FROM part_hierarchy ph
    JOIN part p ON p.p_partkey = ph.p_partkey
    WHERE p.p_size < 30 AND ph.level < 5
),
region_info AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
)
SELECT 
    ph.p_name,
    ph.p_size,
    CONCAT('Manufacturer: ', ph.p_mfgr, ', Brand: ', ph.p_brand) AS manufacturer_brand,
    r.r_name AS region_name,
    ri.nation_count,
    CASE 
        WHEN ph.p_retailprice > 1000 THEN 'High Value'
        WHEN ph.p_retailprice BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS price_category
FROM part_hierarchy ph
JOIN partsupp ps ON ph.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN region_info ri ON r.r_name = ri.r_name
WHERE ph.p_comment LIKE '%fragile%'
ORDER BY ph.p_name, region_name DESC
LIMIT 100;
