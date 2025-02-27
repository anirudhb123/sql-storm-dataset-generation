WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
)
SELECT n.n_name AS nation_name,
       r.r_name AS region_name,
       COUNT(DISTINCT sh.s_suppkey) AS high_balance_suppliers,
       AVG(sh.s_acctbal) AS avg_acct_balance,
       SUM(p.p_retailprice * ps.ps_availqty) AS total_value_of_parts
FROM supplier_hierarchy sh
JOIN nation n ON sh.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE sh.level < 3 AND p.p_size > 10
GROUP BY n.n_name, r.r_name
HAVING AVG(sh.s_acctbal) > 1000
ORDER BY total_value_of_parts DESC
LIMIT 10;
