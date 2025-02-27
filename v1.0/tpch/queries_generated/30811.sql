WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS depth
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.depth + 1
    FROM 
        orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (
        SELECT 
            c.c_custkey 
        FROM 
            customer c 
        WHERE 
            c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'CANADA')
        LIMIT 1
    )
    WHERE 
        o.o_orderdate > current_date - interval '1 year'
)

SELECT 
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS num_orders,
    AVG(p.p_retailprice) AS avg_price,
    MAX(s.s_acctbal) AS max_supplier_balance
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    OrderHierarchy oh ON l.l_orderkey = oh.o_orderkey
WHERE 
    p.p_size IN (SELECT DISTINCT p2.p_size FROM part p2 WHERE p2.p_retailprice < 100.00)
    AND (s.s_acctbal IS NULL OR s.s_acctbal < 5000)
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    revenue > (SELECT AVG(revenue) FROM (
        SELECT 
            SUM(l2.l_extendedprice * (1 - l2.l_discount)) AS revenue 
        FROM 
            lineitem l2 
        GROUP BY 
            l2.l_orderkey
    ) sub)
ORDER BY 
    num_orders DESC, avg_price ASC
LIMIT 10;
