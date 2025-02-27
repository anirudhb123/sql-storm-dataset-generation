WITH RECURSIVE supplier_ranks AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
high_value_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_container,
           COALESCE(NULLIF(SUBSTRING(p.p_comment, 1, 10), ''), 'No Comment') AS part_comment
    FROM part p 
    WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2 
        WHERE p2.p_size > 10 AND p2.p_brand IN ('BrandX', 'BrandY')
    )
),
nation_avg_acctbal AS (
    SELECT n.n_nationkey, AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n 
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey 
    GROUP BY n.n_nationkey
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(supply.high_value_part_count, 0) AS high_value_part_count,
    COALESCE(AVG(nation_avg_acctbal.avg_acctbal), 0) AS avg_supplier_acctbal,
    CASE WHEN supply.high_value_part_count IS NULL THEN 'None' ELSE 'Available' END AS availability_status,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_acctbal, ')'), ', ') AS suppliers
FROM nation n
LEFT JOIN (
    SELECT h.n_nationkey, COUNT(h.p_partkey) AS high_value_part_count
    FROM high_value_parts h 
    JOIN partsupp ps ON h.p_partkey = ps.ps_partkey
    GROUP BY h.n_nationkey
) supply ON n.n_nationkey = supply.n_nationkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey AND s.s_acctbal > (
    SELECT MAX(s2.s_acctbal) 
    FROM supplier s2 
    WHERE s2.s_nationkey = n.n_nationkey AND s2.s_acctbal IS NOT NULL 
    GROUP BY s2.s_nationkey HAVING COUNT(*) > 1
)
JOIN nation_avg_acctbal ON n.n_nationkey = nation_avg_acctbal.n_nationkey
GROUP BY n.n_name, supply.high_value_part_count
HAVING COALESCE(supply.high_value_part_count, 0) > 0 OR AVG(nation_avg_acctbal.avg_acctbal) < 1000
ORDER BY 1 DESC, 2 ASC;
