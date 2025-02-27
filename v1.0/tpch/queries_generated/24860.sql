WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, 
           1 AS level
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(day, -30, CURRENT_DATE)
  
    UNION ALL

    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, 
           oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey 
                                                FROM customer c 
                                                WHERE c.cacctbal > 1000 
                                                AND c.c_nationkey IN (SELECT n.n_nationkey 
                                                                      FROM nation n 
                                                                      WHERE n.n_regionkey = 1))
    WHERE oh.o_orderkey = o.o_orderkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_qty,
    AVG(p.p_retailprice) OVER (PARTITION BY s.s_nationkey) AS avg_supplier_price,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', COALESCE(p.p_comment, 'No comment'), ')'), '; ') FILTER (WHERE p.p_size BETWEEN 1 AND 10) AS part_details
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
INNER JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
INNER JOIN 
    part p ON ps.ps_partkey = p.p_partkey
INNER JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
INNER JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
INNER JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    (l.l_discount > 0.1 OR l.l_tax IS NULL)
    AND COALESCE(p.p_brand, 'UNKNOWN') NOT LIKE 'ABC%'
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    region_name ASC NULLS LAST;
