WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_orderstatus, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_orderstatus, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_orderkey > oh.o_orderkey
)
SELECT 
    n.n_name AS nation, 
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS total_filled,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS total_open,
    AVG(l.l_discount) AS average_discount,
    MAX(l.l_extendedprice) AS max_price,
    MIN(l.l_tax) AS min_tax
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_comment LIKE '%north%')
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    customer_count DESC
LIMIT 5;