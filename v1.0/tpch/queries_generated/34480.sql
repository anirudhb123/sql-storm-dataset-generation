WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
  
    UNION ALL
  
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2)
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(l.l_extendedprice) AS avg_extended_price,
    CASE 
        WHEN SUM(l.l_quantity) IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status
FROM 
    customer c
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    supplier_hierarchy sh ON c.c_nationkey = sh.s_nationkey
WHERE 
    n.r_name IN (SELECT r_name FROM region WHERE r_regionkey IS NOT NULL)
GROUP BY 
    n.n_name
HAVING 
    COUNT(l.l_orderkey) > 5
ORDER BY 
    total_revenue DESC
LIMIT 10;
