WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS total_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
        AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey
),
RevenueRanked AS (
    SELECT 
        o.o_orderkey,
        total_revenue,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        OrderStats o
)
SELECT 
    s.s_name,
    ss.total_available,
    ss.avg_supply_cost,
    r.total_revenue,
    r.revenue_rank
FROM 
    SupplierStats ss
LEFT JOIN 
    partsupp ps ON ss.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    RevenueRanked r ON ss.s_suppkey = (
        SELECT TOP 1 l.l_suppkey
        FROM lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_orderkey = r.o_orderkey
        ORDER BY l.l_extendedprice DESC
    )
WHERE 
    ss.avg_supply_cost IS NOT NULL
    AND r.total_revenue > (
        SELECT AVG(total_revenue)
        FROM RevenueRanked
    )
ORDER BY 
    ss.total_available DESC, 
    r.revenue_rank;
