WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON sh.s_suppkey = s.s_suppkey
    WHERE sh.level < 3
),
aggregated_part AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_size,
    p.p_retailprice,
    COALESCE(expensive_part.total_supplycost, 0) AS total_supplycost,
    SUM(CASE 
        WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) 
        ELSE l.l_extendedprice 
    END) AS total revenue,
    RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied
FROM part p
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN aggregated_part expensive_part ON expensive_part.ps_partkey = p.p_partkey
LEFT JOIN partsupp ps ON ps.ps_partkey = p.p_partkey
LEFT JOIN supplier su ON su.s_suppkey = ps.ps_suppkey
LEFT JOIN nation n ON su.s_nationkey = n.n_nationkey
WHERE p.p_retailprice IS NOT NULL
  AND (p.p_size BETWEEN 5 AND 15 OR p.p_name LIKE '%widget%')
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_size, p.p_retailprice
HAVING SUM(l.l_quantity) > 0
ORDER BY revenue_rank, p.p_partkey;
