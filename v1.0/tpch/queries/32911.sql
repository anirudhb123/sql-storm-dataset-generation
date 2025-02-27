WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey, n.n_name, 
           1 AS level
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey, n.n_name,
           sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE sh.level < 5
)
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_supplycost) AS unique_supplycosts,
    AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_discount END) AS avg_discount_returned,
    SUM(CASE WHEN c.c_mktsegment = 'BUILDING' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_building_sales,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY AVG(l.l_extendedprice) DESC) AS rank_by_avg_price
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN customer c ON c.c_custkey = o.o_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN supplier_hierarchy sh ON sh.n_nationkey = n.n_nationkey
WHERE p.p_retailprice IS NOT NULL 
AND (ps.ps_availqty * ps.ps_supplycost) > 20000
GROUP BY p.p_name, n.n_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 1 
ORDER BY rank_by_avg_price;
