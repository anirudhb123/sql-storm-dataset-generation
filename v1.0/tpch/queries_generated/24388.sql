WITH RECURSIVE RevenueCTE AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        c.c_custkey
    
    UNION ALL
    
    SELECT 
        r.r_regionkey,
        SUM(p.p_retailprice - p.p_retailprice * 0.1) 
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NULL OR (s.s_acctbal > 1000 AND p.p_size > 10)
    GROUP BY 
        r.r_regionkey
)
SELECT 
    COALESCE(c.c_custkey, r.r_regionkey) AS key_identifier,
    COALESCE(r.total_revenue, 0) AS revenue,
    ROW_NUMBER() OVER (PARTITION BY COALESCE(c.c_custkey, r.r_regionkey) ORDER BY revenue DESC) AS rn
FROM 
    (SELECT c_custkey, total_revenue FROM RevenueCTE WHERE c_custkey IS NOT NULL) c
FULL OUTER JOIN 
    (SELECT r.r_regionkey, SUM(revenue) AS total_revenue FROM RevenueCTE r WHERE r.r_regionkey IS NOT NULL GROUP BY r.r_regionkey) r
ON 
    c.c_custkey = r.r_regionkey
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM lineitem l
        WHERE l.l_discount > 0.5 AND l.l_returnflag = 'R'
    )
ORDER BY 
    key_identifier,
    revenue DESC
LIMIT 100 OFFSET (SELECT COUNT(*) FROM lineitem) / 2;
