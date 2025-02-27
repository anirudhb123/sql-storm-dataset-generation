WITH RECURSIVE RegionSales AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    LEFT JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY 
        r.r_regionkey, r.r_name
    UNION ALL
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    INNER JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    INNER JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    INNER JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    INNER JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    WHERE 
        l.l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        r.r_regionkey, r.r_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
CustomerSegments AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment IN ('BUILDING', 'FURNITURE')
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
)
SELECT 
    r.r_name, 
    COALESCE(rs.total_sales, 0) AS total_sales_last_year, 
    COALESCE(hv.order_total, 0) AS high_value_order_total,
    cs.order_count 
FROM 
    region r
LEFT JOIN 
    RegionSales rs ON r.r_regionkey = rs.r_regionkey
LEFT JOIN 
    HighValueOrders hv ON hv.order_total > 1000
LEFT JOIN 
    CustomerSegments cs ON cs.total_spent > 5000
ORDER BY 
    r.r_name;
