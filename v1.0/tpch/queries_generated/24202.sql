WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s1.s_acctbal)
        FROM supplier s1
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), 
part_info AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_comment IS NOT NULL)
), 
customer_orders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders) 
),
subquery_orders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT DISTINCT 
    p.p_name,
    COUNT(DISTINCT co.c_custkey) AS customer_count,
    MAX(pi.ps_supplycost) AS highest_supply_cost,
    MIN(r.r_name) AS region_name,
    CASE 
        WHEN SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) = 0 THEN 'No Returns' 
        ELSE 'Contains Returns' 
    END AS return_status
FROM part_info pi
LEFT JOIN part p ON pi.p_partkey = p.p_partkey
LEFT JOIN supplier_hierarchy sh ON sh.s_suppkey = pi.ps_supplycost
LEFT JOIN customer_orders co ON co.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT o_orderkey FROM subquery_orders))
LEFT JOIN nation n ON n.n_nationkey = sh.s_nationkey
LEFT JOIN region r ON r.r_regionkey = n.n_regionkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
WHERE p.p_name LIKE '%e%' 
  AND (p.p_retailprice IS NOT NULL OR p.p_size > 10)
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT sh.s_nationkey) < 10 
ORDER BY 
    return_status DESC, customer_count ASC;
