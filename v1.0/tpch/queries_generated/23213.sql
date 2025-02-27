WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS lvl
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.lvl + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.lvl < 5
),
customer_order_summary AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent, 
           COUNT(o.o_orderkey) AS total_orders,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
nation_supplier_count AS (
    SELECT n.n_nationkey, 
           n.n_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           MAX(s.s_acctbal) AS max_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT p.p_name, 
       COALESCE(nsc.supplier_count, 0) AS total_suppliers, 
       c.total_spent, 
       sh.lvl AS hierarchy_level,
       CASE 
           WHEN c.total_orders IS NULL THEN 'No Orders' 
           WHEN c.total_orders > 5 THEN 'Frequent Buyer' 
           ELSE 'Occasional Buyer' 
       END AS buyer_category
FROM part p
LEFT JOIN customer_order_summary c ON p.p_partkey % 100 = c.c_custkey % 100
LEFT JOIN nation_supplier_count nsc ON p.p_partkey % 10 = nsc.n_nationkey
LEFT JOIN supplier_hierarchy sh ON nsc.n_nationkey = sh.s_nationkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
AND EXISTS (
    SELECT 1
    FROM partsupp ps
    WHERE ps.ps_partkey = p.p_partkey AND ps.ps_availqty <= 5
)
AND (sh.lvl IS NOT NULL OR c.total_orders IS NOT NULL)
ORDER BY p.p_name, c.total_spent DESC NULLS LAST;
