WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
)
, RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_retailprice > (
        SELECT AVG(ps.ps_supplycost) 
        FROM partsupp ps
        WHERE ps.ps_availqty > 100
    )
)
SELECT 
    n.n_name,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    STRING_AGG(DISTINCT rp.p_name, '; ') AS popular_parts
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    RankedParts rp ON l.l_partkey = rp.p_partkey
LEFT JOIN 
    SupplierHierarchy sh ON l.l_suppkey = sh.s_suppkey
WHERE 
    o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
    AND l.l_shipdate IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    total_revenue > (
        SELECT AVG(total_revenue)
        FROM (
            SELECT 
                SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
            FROM 
                lineitem l
            JOIN 
                orders o ON l.l_orderkey = o.o_orderkey
            WHERE 
                o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
            GROUP BY 
                o.o_orderkey
        ) AS revenue
    )
ORDER BY total_revenue DESC;
