WITH RECURSIVE supplier_hierarchy AS (
    SELECT s1.s_suppkey, s1.s_name, s1.s_nationkey, 0 AS level
    FROM supplier s1
    WHERE s1.s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'FRANCE')
    
    UNION ALL
    
    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, sh.level + 1
    FROM supplier s2
    JOIN supplier_hierarchy sh ON s2.s_nationkey = sh.s_nationkey
    WHERE sh.level < 2
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    s.s_suppkey,
    s.s_name,
    n.n_name AS supplier_nation,
    COUNT(DISTINCT ps.ps_partkey) AS distinct_parts_supplied,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    AVG(l.l_extendedprice) OVER (PARTITION BY s.s_nationkey) AS avg_price_per_nation,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        WHEN cs.total_spent > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_value_category
FROM supplier s
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN customer_orders cs ON cs.c_custkey = s.s_suppkey
WHERE 
    (s.s_acctbal > 500 OR s.s_comment IS NULL)
    AND s.s_nationkey IN (SELECT n_nationkey FROM supplier_hierarchy)
GROUP BY s.s_suppkey, s.s_name, n.n_name, cs.total_spent
ORDER BY total_quantity DESC
FETCH FIRST 10 ROWS ONLY;
