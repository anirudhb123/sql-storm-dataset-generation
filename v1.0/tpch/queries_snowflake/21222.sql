WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey != sh.s_suppkey AND s.s_acctbal > 5000
),
price_variance AS (
    SELECT ps.ps_partkey, 
           AVG(ps.ps_supplycost) AS avg_cost,
           STDDEV(ps.ps_supplycost) AS std_dev_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
part_supplier_info AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, 
           COALESCE(sh.level, -1) AS supplier_level, 
           COALESCE(cv.avg_cost, 0) AS avg_supply_cost,
           CASE 
               WHEN p.p_retailprice IS NULL THEN 'Unknown' 
               WHEN p.p_retailprice < 20 THEN 'Low'
               WHEN p.p_retailprice BETWEEN 20 AND 100 THEN 'Medium'
               ELSE 'High' 
           END AS price_category
    FROM part p
    LEFT JOIN supplier_hierarchy sh ON p.p_partkey = sh.s_suppkey
    LEFT JOIN price_variance cv ON p.p_partkey = cv.ps_partkey
    WHERE p.p_type LIKE '%brass%' AND (p.p_container IS NULL OR p.p_container != 'small')
),
final_selection AS (
    SELECT psi.p_partkey, psi.p_name, psi.p_brand, psi.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY psi.price_category ORDER BY psi.p_retailprice DESC) AS rank_within_category
    FROM part_supplier_info psi
    WHERE psi.supplier_level IN (SELECT DISTINCT sh.level FROM supplier_hierarchy sh WHERE sh.level > -1)
    AND psi.avg_supply_cost > (SELECT AVG(avg_cost) FROM price_variance pv WHERE pv.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps))
)
SELECT fs.p_partkey, fs.p_name, fs.p_brand, fs.p_retailprice, fs.rank_within_category
FROM final_selection fs
WHERE fs.rank_within_category <= 5
ORDER BY fs.p_retailprice DESC
FETCH FIRST 10 ROWS ONLY;
