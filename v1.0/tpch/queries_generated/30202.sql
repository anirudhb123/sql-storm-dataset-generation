WITH RECURSIVE SupplyChain AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        1 AS level 
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty > 0

    UNION ALL

    SELECT 
        p.ps_partkey,
        p.ps_suppkey,
        p.ps_availqty - 10 AS ps_availqty,
        p.ps_supplycost * 0.9 AS ps_supplycost,
        sc.level + 1 
    FROM 
        SupplyChain sc
    JOIN 
        partsupp p ON sc.ps_partkey = p.ps_partkey
    WHERE 
        sc.level < 5
)

SELECT 
    p.p_name, 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    AVG(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY p.p_partkey) AS avg_price_after_discount,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    s.s_name AS supplier_name,
    n.n_name AS nation_name 
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplyChain sc ON p.p_partkey = sc.ps_partkey
WHERE 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31' 
    AND (s.s_acctbal IS NOT NULL OR n.n_comment IS NULL)
GROUP BY 
    p.p_name, s.s_name, n.n_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    avg_price_after_discount DESC
LIMIT 10;
