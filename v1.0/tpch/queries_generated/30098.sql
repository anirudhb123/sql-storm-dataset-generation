WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS hierarchy_level
    FROM nation
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, h.hierarchy_level + 1
    FROM nation n
    INNER JOIN NationHierarchy h ON n.n_regionkey = h.n_nationkey
)

SELECT 
    c.c_custkey,
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 THEN 'High Value'
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
WHERE o.o_orderdate >= '2023-01-01'
AND c.c_nationkey IN (SELECT n_nationkey FROM NationHierarchy)
GROUP BY c.c_custkey, c.c_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) IS NOT NULL
ORDER BY total_revenue DESC
LIMIT 10;

SELECT p.p_name, 
       AVG(ps.ps_supplycost) AS avg_supply_cost,
       MAX(ps.ps_availqty) AS max_available_quantity,
       COALESCE(STRING_AGG(ps.ps_comment, '; '), 'No comments') AS comments
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY p.p_name
HAVING MAX(ps.ps_availqty) > 0
UNION ALL
SELECT 'TOTAL' AS p_name, 
       AVG(ps.ps_supplycost) AS avg_supply_cost,
       SUM(ps.ps_availqty) AS total_available_quantity,
       'Aggregate comments' AS comments
FROM partsupp ps;
