WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey AND s.s_acctbal < sh.s_acctbal
    WHERE sh.level < 10
),
high_value_parts AS (
    SELECT p_partkey, p_name, p_retailprice
    FROM part
    WHERE p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
    AND p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost < 100.00) 
),
aggregated_orders AS (
    SELECT o.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY o.o_custkey
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT 
    n.n_name,
    r.r_name,
    COALESCE(sh.s_name, 'No Supplier') AS supplier_name,
    COUNT(DISTINCT p.p_partkey) AS product_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END) AS total_returned_value,
    AVG(l.l_discount) OVER (PARTITION BY n.n_nationkey ORDER BY o.o_orderdate ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS avg_discount,
    STRING_AGG(DISTINCT p.p_comment, '; ') FILTER (WHERE p.p_size IS NOT NULL) AS comments
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN lineitem l ON l.l_suppkey = sh.s_suppkey
LEFT JOIN high_value_parts p ON l.l_partkey = p.p_partkey
LEFT JOIN aggregated_orders ao ON ao.c_custkey = l.l_orderkey
WHERE 
    r.r_name LIKE 'A%' 
    AND (n.n_comment IS NULL OR LENGTH(n.n_comment) > 50)
GROUP BY n.n_name, r.r_name, sh.s_name
ORDER BY product_count DESC, n.n_name;
