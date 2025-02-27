WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS order_level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1997-01-01'
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, co.order_level + 1
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE o.o_orderdate > co.o_orderdate
)
SELECT 
    c.c_custkey,
    c.c_name,
    SUM(o.o_totalprice) AS total_spent,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT p.p_name, ', ') AS purchased_parts,
    AVG(CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END) AS avg_supplier_balance
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    (c.c_acctbal > 0 OR c.c_mktsegment = 'Retail')
    AND o.o_orderstatus = 'F'
GROUP BY 
    c.c_custkey, c.c_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 2
ORDER BY 
    total_spent DESC
LIMIT 10;