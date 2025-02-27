WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 1 AS level
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name = 'USA'
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, sh.level + 1
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN SupplierHierarchy sh ON s.s_acctbal < sh.s_acctbal
)

SELECT 
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE NULL
        END) AS average_returned_price,
    DENSE_RANK() OVER (PARTITION BY sh.nation_name ORDER BY SUM(l.l_extendedprice) DESC) AS revenue_rank
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
WHERE 
    ps.ps_availqty > 0
    AND p.p_brand LIKE 'Brand#%'
    AND sh.level <= 3
GROUP BY 
    p.p_partkey, p.p_name, sh.nation_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    revenue DESC
LIMIT 10;
