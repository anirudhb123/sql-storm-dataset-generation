WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, 0 AS level
    FROM customer
    WHERE c_acctbal IS NOT NULL AND c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_custkey = (SELECT c2.c_custkey
                                                FROM customer c2
                                                WHERE c2.c_acctbal < ch.c_acctbal
                                                ORDER BY c2.c_acctbal DESC
                                                LIMIT 1)
)
SELECT 
    n.n_name,
    p.p_name,
    COALESCE(SUM(l.l_discount * l.l_extendedprice * (1 - CASE 
        WHEN l.l_returnflag = 'R' THEN 0.1 
        ELSE 0 
    END)), 0) AS total_discounted_sales,
    COUNT(DISTINCT c.c_custkey) AS distinct_customers,
    ROW_NUMBER() OVER(PARTITION BY n.n_name ORDER BY total_discounted_sales DESC) AS sales_rank
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 20)
    AND l.l_shipdate > DATEADD('day', -30, CURRENT_DATE)
    AND n.n_name IS NOT NULL
GROUP BY 
    n.n_name, p.p_name, c.c_name
HAVING 
    COUNT(l.l_orderkey) > 5
    OR total_discounted_sales > 1000
ORDER BY 
    total_discounted_sales DESC, n.n_name DESC
FETCH FIRST 50 ROWS ONLY
UNION ALL
SELECT 
    'Total',
    NULL,
    SUM(total_discounted_sales),
    COUNT(DISTINCT c.c_custkey) 
FROM (
    SELECT 
        n.n_name,
        COALESCE(SUM(l.l_discount * l.l_extendedprice * (1 - CASE 
            WHEN l.l_returnflag = 'R' THEN 0.1 
            ELSE 0 
        END)), 0) AS total_discounted_sales,
        c.c_custkey
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 20)
        AND l.l_shipdate > DATEADD('day', -30, CURRENT_DATE)
    GROUP BY 
        n.n_name, c.c_custkey
) AS summary;
