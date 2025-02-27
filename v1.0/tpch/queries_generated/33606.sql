WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal <= (SELECT AVG(s_acctbal) FROM supplier) 
)
SELECT 
    p.p_partkey, 
    p.p_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    CONCAT('Total Revenue for ', p.p_name, ' is $', ROUND(SUM(l.l_extendedprice * (1 - l.l_discount)), 2)) AS revenue_statement
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name IS NOT NULL 
    AND o.o_orderdate >= '2023-01-01' 
    AND o.o_orderstatus = 'O' 
GROUP BY 
    p.p_partkey, p.p_name, s.s_name
HAVING 
    total_revenue > (SELECT AVG(total_revenue) FROM (
        SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
        FROM lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        GROUP BY o.o_orderkey
    ) AS revenue_summary)
ORDER BY 
    total_revenue DESC
LIMIT 10;
