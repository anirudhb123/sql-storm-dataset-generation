WITH RECURSIVE suppliers_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN suppliers_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5  -- Limit recursion depth
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice ELSE NULL END) AS avg_discounted_price,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice) DESC) AS revenue_rank
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY 
    n.n_name
HAVING 
    SUM(l.l_extendedprice) > 1000000
ORDER BY 
    total_revenue DESC
LIMIT 10;
