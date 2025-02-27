WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_comment, 0 AS level
    FROM part
    WHERE p_size IS NULL
    
    UNION ALL
    
    SELECT p.p_partkey, p.p_name, p.p_comment, ph.level + 1
    FROM part_hierarchy ph
    JOIN partsupp ps ON ph.p_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ph.level < 5
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 100
    GROUP BY c.c_custkey, c.c_name
),
supplier_stats AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END) AS total_available,
           AVG(NULLIF(s.s_acctbal, 0)) AS avg_account_balance
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT DISTINCT
    c.c_name AS customer_name,
    COALESCE(CAST(STRING_AGG(DISTINCT ph.p_name, ', ') AS VARCHAR), 'No parts') AS part_names,
    cs.order_count,
    ss.total_available,
    ss.avg_account_balance
FROM customer_orders cs
FULL OUTER JOIN supplier_stats ss ON cs.order_count IS NOT NULL AND ss.total_available > 0
LEFT JOIN part_hierarchy ph ON cs.c_custkey = ph.p_partkey
WHERE (cs.total_spent > 5000 OR ss.avg_account_balance > 10000)
  AND ph.level IS NOT NULL
  AND (ph.p_comment NOT LIKE '%test%' OR ph.p_comment IS NULL)
ORDER BY customer_name DESC, order_count ASC
FETCH FIRST 10 ROWS ONLY;
