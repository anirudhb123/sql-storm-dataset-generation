
WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_type, p_size, p_retailprice, 
           1 AS level
    FROM part
    WHERE p_size IN (SELECT DISTINCT p_size FROM part WHERE p_type LIKE 'small%')
    
    UNION ALL
    
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_type, p.p_size, p.p_retailprice,
           ph.level + 1
    FROM part p
    JOIN part_hierarchy ph ON ph.p_partkey = p.p_partkey
    WHERE p.p_retailprice < 100
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS order_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT ph.p_name, ph.p_mfgr, ph.p_type, ph.p_size, ph.p_retailprice,
       os.total_revenue, cs.total_spent, 
       CASE 
           WHEN cs.total_spent IS NULL THEN 'No Purchases' 
           ELSE 'Purchaser' 
       END AS purchase_status
FROM part_hierarchy ph
LEFT JOIN order_summary os ON ph.p_partkey = os.o_orderkey
FULL JOIN customer_summary cs ON cs.total_spent > 500
WHERE ph.level <= 3
  AND (ph.p_size IS NOT NULL AND ph.p_size > 0)
  AND ph.p_retailprice BETWEEN 10 AND 500
ORDER BY ph.p_retailprice DESC, cs.total_spent ASC;
