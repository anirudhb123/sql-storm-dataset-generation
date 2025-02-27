WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 
           ROW_NUMBER() OVER (PARTITION BY n_regionkey ORDER BY n_nationkey) AS rn
    FROM nation
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE 'A%')
    UNION ALL
    SELECT n_nationkey, CONCAT(n_name, ' (Subregion)') AS n_name, n_regionkey, 
           ROW_NUMBER() OVER (PARTITION BY n_regionkey ORDER BY n_nationkey) + rn
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    SUM(ps.ps_availqty) AS total_available_quantity,
    MAX(l.l_shipdate) AS last_ship_date,
    AVG(p.p_retailprice) OVER (PARTITION BY p.p_mfgr) AS avg_retail_price_by_mfgr,
    CASE 
        WHEN SUM(ps.ps_supplycost) IS NULL OR avg(p.p_retailprice) < 0 THEN 'Unknown' 
        ELSE 'Known' 
    END AS availability_status,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey AND l.l_orderkey IN (
    SELECT o_orderkey FROM orders WHERE o_orderstatus = 'O'
)
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
FULL OUTER JOIN nation_hierarchy nh ON s.s_nationkey = nh.n_nationkey
WHERE p.p_size BETWEEN 1 AND 10
  AND (p.p_comment IS NULL OR p.p_comment LIKE '%Fresh%')
GROUP BY p.p_partkey, p.p_name, p.p_mfgr
HAVING COUNT(DISTINCT l.l_orderkey) > (
    SELECT COUNT(*) FROM customer c WHERE c.c_acctbal < 1000
)
ORDER BY total_available_quantity DESC
LIMIT 50 OFFSET 100;
