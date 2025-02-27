WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        0 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000

    UNION ALL

    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        sc.level + 1
    FROM 
        SupplyChain sc
    JOIN 
        partsupp ps ON ps.ps_suppkey = sc.s_suppkey
    JOIN 
        supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        sc.level < 5
)

SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    CASE 
        WHEN SUM(l.l_discount) > 0.1 THEN 'Discounted'
        ELSE 'Regular'
    END AS pricing_category
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND (n.n_name IS NOT NULL OR l.l_tax > 0)
GROUP BY 
    p.p_name, n.n_nationkey
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    revenue DESC;
