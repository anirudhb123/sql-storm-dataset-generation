WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_orderdate,
        o_totalprice,
        1 AS level
    FROM 
        orders
    WHERE 
        o_orderstatus = 'O'

    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.level + 1
    FROM 
        orders o
    INNER JOIN 
        OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE 
        o.o_orderdate > oh.o_orderdate
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    SUM(o.o_totalprice) AS total_sales,
    AVG(o.o_totalprice) AS avg_order_value,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT p.p_name, ', ') AS popular_parts,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(o.o_totalprice) DESC) AS sales_rank
FROM 
    customer c
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    AND (l.l_discount > 0.05 OR l.l_tax < 0.1)
GROUP BY 
    n.n_name
HAVING 
    COUNT(o.o_orderkey) > 10
ORDER BY 
    total_sales DESC, n.n_name ASC;
