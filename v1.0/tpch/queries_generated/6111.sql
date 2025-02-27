WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA'))
   
    UNION ALL

    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN supplier_hierarchy sh ON ps.ps_partkey = sh.s_suppkey
)
SELECT 
    p.p_mfgr,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(o.o_totalprice) AS average_order_value,
    SUM(l.l_discount) AS total_discount,
    SUM(l.l_tax) AS total_tax
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier_hierarchy sh ON ps.ps_suppkey = sh.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
WHERE 
    sh.level < 2 
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_mfgr
ORDER BY 
    customer_count DESC, average_order_value DESC
LIMIT 100;
