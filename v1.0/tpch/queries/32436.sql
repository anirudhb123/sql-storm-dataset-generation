WITH RECURSIVE Customer_History AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS order_level
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        ch.c_custkey,
        ch.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ch.order_level + 1
    FROM 
        Customer_History ch
    JOIN 
        orders o ON ch.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate > (SELECT MAX(o2.o_orderdate) FROM orders o2 WHERE o2.o_custkey = ch.c_custkey)
)

SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT ch.c_custkey) AS total_customers,
    SUM(ch.o_totalprice) AS total_revenue,
    AVG(ch.o_totalprice) AS avg_order_value,
    MAX(ch.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT p.p_name || ' (Size: ' || p.p_size || ')', ', ') AS products_ordered
FROM 
    Customer_History ch
JOIN 
    customer c ON ch.c_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    lineitem l ON ch.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
