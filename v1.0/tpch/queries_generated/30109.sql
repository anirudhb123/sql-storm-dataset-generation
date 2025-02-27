WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'GERMANY')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, sh.level + 1
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN SupplierHierarchy sh ON ps.ps_partkey = (
        SELECT p.p_partkey
        FROM part p
        WHERE p.p_container LIKE 'SMALL%'
        ORDER BY p.p_retailprice DESC
        LIMIT 1
    )
)

SELECT
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
FROM
    customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = l.l_suppkey
WHERE
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND (c.c_acctbal IS NOT NULL OR c.c_mktsegment <> 'AUTOMOBILE')
GROUP BY
    c.c_name, c.c_nationkey
HAVING
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY
    total_revenue DESC
LIMIT 10;
