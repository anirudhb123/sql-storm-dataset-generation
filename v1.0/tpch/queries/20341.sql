
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s 
    WHERE s.s_acctbal > 10000  

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND sh.level < 5  
),

customer_orders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(CAST(sh.level AS TEXT), 'No hierarchy') AS supplier_hierarchy_level,
    COALESCE(NULLIF(c.order_count, 0), NULL) AS number_of_orders,
    COALESCE(c.total_spent, 0) AS total_spent,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY c.total_spent DESC) AS rank_spent
FROM 
    part p
FULL OUTER JOIN supplier_hierarchy sh ON sh.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps 
    WHERE ps.ps_partkey = p.p_partkey 
    ORDER BY ps.ps_supplycost ASC
    LIMIT 1
)
LEFT JOIN customer_orders c ON c.c_custkey = (
    SELECT MAX(c2.c_custkey)
    FROM customer_orders c2
    WHERE c2.total_spent BETWEEN 500 AND 5000
) OR c.c_custkey IS NULL
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
    OR EXISTS (SELECT 1 FROM lineitem l WHERE l.l_discount > 0.2 AND l.l_partkey = p.p_partkey)
ORDER BY 
    p.p_partkey, rank_spent DESC;
