WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, sh.level + 1 
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
)

SELECT 
    n.n_name,
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    l.l_shipdate > '1997-01-01' AND
    o.o_orderstatus = 'O' AND
    (s.s_acctbal IS NULL OR s.s_acctbal > 500) 
GROUP BY 
    n.n_name, r.r_name
HAVING 
    SUM(l.l_extendedprice) > 10000 AND
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_revenue DESC;