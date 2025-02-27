WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.level < 3
), total_sales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
), high_sales AS (
    SELECT ts.o_orderkey, ts.total_price
    FROM total_sales ts
    WHERE ts.total_price > 10000
), nation_suppliers AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING SUM(s.s_acctbal) IS NOT NULL
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    ns.n_name,
    sh.level,
    ns.total_acctbal,
    hs.total_price
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier_hierarchy sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN nation_suppliers ns ON ps.ps_suppkey = ns.n_nationkey
LEFT JOIN high_sales hs ON ps.ps_partkey = hs.o_orderkey
WHERE p.p_retailprice BETWEEN 50.00 AND 500.00
  AND (sh.level IS NULL OR sh.level <= 2)
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    p.p_retailprice, 
    ns.n_name, 
    sh.level, 
    ns.total_acctbal,
    hs.total_price
ORDER BY p.p_partkey DESC
LIMIT 100;
