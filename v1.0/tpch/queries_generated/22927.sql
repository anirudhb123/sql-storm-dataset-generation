WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
)
SELECT r.r_name, 
       COUNT(DISTINCT n.n_nationkey) AS nation_count,
       SUM(ps.ps_availqty) AS total_available_quantity,
       AVG(p.p_retailprice) filtered_avg_price,
       STRING_AGG(DISTINCT c.c_name ORDER BY c.c_name) AS customer_names,
       SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) END) AS total_discounted_sales,
       MAX(l.l_tax) AS max_tax,
       p.p_comment,
       ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
WHERE r.r_name IS NOT NULL 
  AND (n.n_comment IS NULL OR LENGTH(n.n_comment) > 10)
  AND l.l_shipmode NOT IN ('MAIL', 'SHIP')
GROUP BY r.r_name, p.p_comment
HAVING COUNT(DISTINCT sh.s_suppkey) > 5
ORDER BY nation_count DESC, total_available_quantity DESC
LIMIT 10;
