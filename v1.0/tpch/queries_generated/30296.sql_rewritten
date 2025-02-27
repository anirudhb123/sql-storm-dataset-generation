WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'Germany')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS fulfilled_orders,
    AVG(ps.ps_supplycost * l.l_quantity) AS avg_supply_cost,
    MAX(l.l_discount) AS max_discount,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN orders o ON o.o_custkey = s.s_suppkey
JOIN customer c ON c.c_custkey = o.o_custkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    r.r_name IN ('Europe', 'Asia') AND
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY r.r_regionkey, r.r_name
HAVING 
    AVG(l.l_extendedprice) > 100.00 OR
    SUM(l.l_quantity) IS NOT NULL
ORDER BY total_customers DESC, avg_supply_cost ASC;