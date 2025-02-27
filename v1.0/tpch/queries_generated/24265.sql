WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
        WHERE s_nationkey IS NOT NULL
    )
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE sh.level < 5
)
SELECT 
    n.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS ranking
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    AND (c.c_acctbal IS NULL OR c.c_mktsegment LIKE 'B%')
GROUP BY n.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (
    SELECT AVG(SUM(l_inner.l_extendedprice * (1 - l_inner.l_discount)))
    FROM lineitem l_inner
    JOIN orders o_inner ON l_inner.l_orderkey = o_inner.o_orderkey
    WHERE o_inner.o_orderdate < DATE '2023-01-01'
    GROUP BY l_inner.l_orderkey
    HAVING COUNT(*) > 1
)
ORDER BY revenue DESC
LIMIT 10
UNION ALL
SELECT 
    'Total Revenue' AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    NULL AS ranking
FROM lineitem l
WHERE l.l_shipdate < DATE '2023-01-01';
