WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderMetrics AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_linenumber) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        o.* 
    FROM 
        OrderMetrics o
    WHERE 
        o.rnk <= 10
)
SELECT 
    s.s_name,
    COALESCE(o.o_orderkey, -1) AS order_key,
    STATS.total_available,
    STATS.avg_supply_cost,
    STATS.total_parts,
    o.line_count,
    o.net_revenue
FROM 
    SupplierStats STATS
LEFT JOIN 
    TopOrders o ON STATS.total_parts = (
        SELECT COUNT(DISTINCT ps.ps_partkey)
        FROM partsupp ps
        WHERE ps.ps_suppkey = STATS.s_suppkey
    )
ORDER BY 
    STATS.total_available DESC, 
    o.net_revenue DESC NULLS LAST;
