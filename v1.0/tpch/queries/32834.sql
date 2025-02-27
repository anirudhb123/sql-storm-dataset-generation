
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, CAST(s.s_name AS VARCHAR(255)) AS path, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL)
  
    UNION ALL

    SELECT s.s_suppkey, s.s_name, CONCAT(sh.path, ' -> ', s.s_name), sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    r.r_name AS region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(l.l_shipdate) AS last_ship_date,
    SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_quantity 
            ELSE 0 
        END) AS total_returned
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_size >= 10 
    AND r.r_name IS NOT NULL
    AND o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY p.p_partkey, p.p_name, p.p_mfgr, r.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY total_sales DESC
LIMIT 20;
