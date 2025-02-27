WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.level < 3 AND s.s_acctbal IS NOT NULL
),
active_ordering AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) 
                              ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice IS NOT NULL
),
large_customer AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 10000
),
parts_supplier_info AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 0
    ORDER BY supplier_count desc
)
SELECT ps.p_name, 
       ps.p_retailprice, 
       COALESCE(s.s_name, 'No Supplier') AS supplier_name,
       CASE 
           WHEN a.o_orderkey IS NOT NULL THEN 'Active Order' 
           ELSE 'No Active Order' 
       END AS order_status,
       CASE 
           WHEN c.total_spent IS NOT NULL THEN 'High Roller'
           ELSE 'General Customer' 
       END AS customer_category,
       COUNT(DISTINCT sh.s_suppkey) OVER() AS total_high_acct_suppliers
FROM parts_supplier_info ps
LEFT JOIN supplier s ON ps.p_partkey = s.s_suppkey
LEFT JOIN active_ordering a ON a.o_orderkey = s.s_suppkey
LEFT JOIN large_customer c ON c.c_custkey = s.s_suppkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = s.s_nationkey
WHERE ps.p_retailprice < ALL (SELECT p.p_retailprice 
                                FROM part p 
                                WHERE p.p_size IS NULL OR p.p_size < 10)
AND (s.s_acctbal IS NOT NULL OR c.total_spent IS NULL)
ORDER BY ps.p_name, total_high_acct_suppliers DESC;
