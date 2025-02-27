WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, CAST(s_name AS varchar(55)) AS full_name, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, CONCAT(sh.full_name, ' -> ', s.s_name), sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_nationkey
)
SELECT
    p.p_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    AVG(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice ELSE NULL END) AS avg_discounted_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT s.s_name || ' (' || supplier_hierarchy.full_name || ')', ', ') AS suppliers,
    r.r_name AS region
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice BETWEEN 10 AND 500
    AND (o.o_orderdate >= '2023-01-01' OR o.o_orderdate IS NULL)
    AND l.l_shipdate < COALESCE(l.l_commitdate, CURRENT_DATE) 
    AND EXISTS (
        SELECT 1 
        FROM partsupp ps2 
        WHERE ps2.ps_partkey = p.p_partkey 
        AND ps2.ps_availqty IS NOT NULL
    )
GROUP BY r.r_name, p.p_name
HAVING COUNT(o.o_orderkey) > 5
ORDER BY total_returned DESC, avg_discounted_price DESC
LIMIT 50;
