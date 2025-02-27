WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        1 AS Level
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01'

    UNION ALL

    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        oh.Level + 1
    FROM 
        orders o
    INNER JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE 
        o.o_orderdate > oh.o_orderdate
)

SELECT 
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity,
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT o.o_orderkey) DESC) AS order_rank
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    c.c_acctbal > 10000 AND 
    (c.c_mktsegment = 'BUILDING' OR c.c_mktsegment = 'FURNITURE') AND 
    EXISTS (
        SELECT 1 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_retailprice > 50
        ) 
        AND ps.ps_supplycost < 20
    )
GROUP BY 
    c.c_name
HAVING 
    AVG(l.l_discount) < 0.1
ORDER BY 
    total_revenue DESC
LIMIT 10;