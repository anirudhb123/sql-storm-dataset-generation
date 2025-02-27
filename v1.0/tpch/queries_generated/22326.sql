WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           CAST(s.s_name AS VARCHAR(50)) AS full_path
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           CAST(CONCAT(sh.full_path, ' -> ', s.s_name) AS VARCHAR(50))
    FROM supplier s
    JOIN supplier_hierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
)

SELECT DISTINCT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    ps.ps_supplycost,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) OVER (PARTITION BY p.p_partkey) AS avg_supplier_balance,
    COALESCE(r.r_name, 'No Region') AS region_name
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN nation n ON n.n_nationkey = s.s_nationkey
LEFT JOIN region r ON r.r_regionkey = n.n_regionkey
WHERE (l.l_returnflag = 'N' AND l.l_linestatus = 'O') 
  OR (l.l_returnflag IS NULL AND l.l_linestatus IS NULL)
GROUP BY p.p_partkey, p.p_name, p.p_brand, ps.ps_supplycost, r.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 
       (SELECT AVG(sub.total_revenue) 
        FROM (SELECT SUM(l2.l_extendedprice * (1 - l2.l_discount)) AS total_revenue 
              FROM lineitem l2 
              GROUP BY l2.l_orderkey) sub)
ORDER BY region_name DESC, total_revenue DESC
LIMIT 100;
