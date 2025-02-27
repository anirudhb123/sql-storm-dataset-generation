WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_custkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    SUM(COALESCE(l.l_quantity, 0)) AS total_quantity,
    AVG(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE NULL END) AS avg_discounted_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT CASE WHEN n.n_name IS NULL THEN 'UNKNOWN' ELSE n.n_name END, ', ') AS nations_involved,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice) DESC) AS rank
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice BETWEEN 10 AND 100
    AND (p.p_size IS NULL OR p.p_size > 5) 
    AND EXISTS (
        SELECT 1 FROM CustomerHierarchy ch WHERE ch.c_custkey = c.c_custkey 
        AND ch.level < 3
    )
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand
HAVING 
    total_quantity > 100
    AND COUNT(o.o_orderkey) > 5
    OR ANY_VALUE(s.s_acctbal) IS NOT NULL
ORDER BY 
    rank DESC, total_quantity ASC
LIMIT 100;
