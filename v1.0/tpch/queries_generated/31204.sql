WITH RECURSIVE CustomerRank AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        1 AS rank_level
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000

    UNION ALL

    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        cr.rank_level + 1
    FROM 
        customer c
    JOIN 
        CustomerRank cr ON c.c_acctbal IS NOT NULL AND c.c_acctbal > cr.c_acctbal
)

SELECT 
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank,
    COALESCE(r.r_name, 'Unknown Region') AS supplied_region
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    EXISTS (SELECT 1 FROM CustomerRank cr WHERE cr.c_custkey = o.o_custkey AND cr.rank_level > 1)
GROUP BY 
    p.p_partkey, p.p_name, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
ORDER BY 
    total_sales DESC;
