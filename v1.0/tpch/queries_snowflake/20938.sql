
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS rank_lowest_cost
    FROM 
        part p
    WHERE 
        p.p_container IN ('SM BOX', 'MED BOX', 'LG BOX')
), 

HighMarginSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        (s.s_acctbal - AVG(ps.ps_supplycost) OVER()) AS profit_margin
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 500
)

SELECT 
    n.n_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    ARRAY_AGG(DISTINCT p.p_name) AS product_names
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
WHERE 
    l.l_shipdate >= CURRENT_DATE - INTERVAL '6 months'
    AND (s.s_phone IS NULL OR s.s_phone LIKE '%555%')
    AND p.p_partkey IN (
        SELECT rp.p_partkey
        FROM RankedParts rp
        WHERE rp.rank_lowest_cost <= 3 
    )
GROUP BY 
    n.n_name
HAVING 
    SUM(l.l_extendedprice) IS NOT NULL 
    AND COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
