WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           1 AS level, 
           CAST(s.s_name AS VARCHAR(255)) AS path
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT sh.s_suppkey, s.s_name, s.s_acctbal, 
           sh.level + 1, 
           CAST(sh.path || ' -> ' || s.s_name AS VARCHAR(255))
    FROM supplier_hierarchy sh
    JOIN supplier s ON sh.s_suppkey = s.s_suppkey
)
, cte_price AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    WHERE l.l_shipdate >= '1995-01-01' 
      AND l.l_shipdate < '1996-01-01'
    GROUP BY l.l_orderkey
)
SELECT 
    r.r_name, 
    n.n_name, 
    p.p_type, 
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(CASE WHEN ps.ps_availqty > 0 THEN ps.ps_supplycost ELSE NULL END) AS avg_supplycost,
    MAX(l.l_extendedprice) FILTER (WHERE l.l_discount > 0.1) AS max_discounted_price,
    ARRAY_AGG(DISTINCT CONCAT(s.s_name, ':', s.s_acctbal) ORDER BY s.s_acctbal DESC) AS supplier_details
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN cte_price cp ON cp.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'F'
) 
JOIN lineitem l ON cp.l_orderkey = l.l_orderkey
LEFT JOIN customer c ON c.c_custkey IN (
        SELECT o.o_custkey 
        FROM orders o 
        WHERE o.o_orderkey = l.l_orderkey
    )
WHERE p.p_size BETWEEN 1 AND 20
  AND (p.p_retailprice IS NOT NULL AND p.p_retailprice >= (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_container = 'SMALL BOX'))
GROUP BY r.r_name, n.n_name, p.p_type
HAVING COUNT(CASE WHEN c.c_acctbal IS NOT NULL THEN 1 END) > 10
ORDER BY customer_count DESC, r.r_name;
