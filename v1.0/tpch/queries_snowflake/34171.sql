WITH RECURSIVE EmployeeHierarchy AS (
    SELECT s.s_suppkey AS supplier_id, s.s_name AS supplier_name, 
           s.s_acctbal, s.s_comment, 0 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_acctbal, s.s_comment, eh.hierarchy_level + 1
    FROM partsupp ps
    JOIN EmployeeHierarchy eh ON ps.ps_suppkey = eh.supplier_id
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    p.p_partkey, p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank,
    (SELECT COUNT(DISTINCT o.o_orderkey) 
     FROM orders o 
     WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31') AS total_orders_in_year,
    COALESCE(r.r_comment, 'No Comment') AS region_comment
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 20 AND 
    (s.s_acctbal IS NOT NULL OR s.s_comment <> '') 
GROUP BY 
    p.p_partkey, p.p_name, r.r_comment
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_sales DESC 
LIMIT 10;