WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice BETWEEN 10 AND 100
      AND sh.level < 3
)
SELECT n.n_name AS nation, 
       COUNT(DISTINCT c.c_custkey) AS customer_count, 
       COALESCE(SUM(o.o_totalprice), 0) AS total_revenue,
       AVG(s.s_acctbal) AS average_supplier_balance,
       SUM(CASE WHEN li.l_discount > 0.1 THEN li.l_extendedprice ELSE 0 END) AS discount_revenue,
       ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY COALESCE(SUM(o.o_totalprice), 0) DESC) AS revenue_rank
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN orders o ON li.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
WHERE n.n_comment IS NOT NULL
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 0 AND average_supplier_balance >= 1000
ORDER BY total_revenue DESC
LIMIT 10;
