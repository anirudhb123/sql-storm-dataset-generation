WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), 
part_supplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), 
customer_orders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_retailprice, 
    COALESCE(ps.total_supplycost, 0) AS total_supplycost,
    CASE 
        WHEN co.order_count IS NULL THEN 'No Orders' 
        ELSE 'With Orders' 
    END AS order_status,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank,
    COUNT(DISTINCT sh.s_nationkey) OVER (PARTITION BY p.p_partkey) AS supplier_nations
FROM part p
LEFT JOIN part_supplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN customer_orders co ON p.p_partkey = co.c_custkey
LEFT JOIN supplier_hierarchy sh ON sh.s_suppkey = ps.ps_suppkey
WHERE p.p_size BETWEEN 1 AND 10
AND (p.p_comment IS NULL OR p.p_comment LIKE '%special%')
AND EXISTS (
    SELECT 1
    FROM supplier s
    WHERE s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey LIMIT 1)
    AND s.s_acctbal < 100
)
ORDER BY p.p_partkey, total_supplycost DESC
FETCH FIRST 100 ROWS ONLY;
