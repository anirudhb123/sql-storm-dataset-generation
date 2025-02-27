WITH SupplierOrderStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        s.s_suppkey, s.s_name
),
NullHandlingExample AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
    HAVING 
        COUNT(s.s_suppkey) IS NULL OR COUNT(s.s_suppkey) > 0
),
AverageOrderValue AS (
    SELECT 
        c.c_custkey,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    COALESCE(SUM(sos.total_revenue), 0) AS total_revenue,
    NO_MORE_THAN_2(s.total_revenue) AS limited_revenue,
    nhe.supplier_count,
    aov.avg_order_value
FROM 
    region r
LEFT JOIN 
    SupplierOrderStats sos ON r.r_regionkey = 
        (SELECT DISTINCT n.n_regionkey FROM nation n WHERE n.n_name LIKE 'A%')
LEFT JOIN 
    NullHandlingExample nhe ON r.r_name = nhe.n_name
LEFT JOIN 
    AverageOrderValue aov ON aov.avg_order_value > 1000
GROUP BY 
    r.r_name, nhe.supplier_count, aov.avg_order_value
HAVING 
    COUNT(sos.s_suppkey) > 0 OR COUNT(nhe.supplier_count) IS NOT NULL;
