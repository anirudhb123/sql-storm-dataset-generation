WITH RECURSIVE NationOrders AS (
    SELECT 
        n.n_name AS nation_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_revenue
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
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        n.n_name
    
    UNION ALL
    
    SELECT 
        'Total' AS nation_name, 
        SUM(order_count),
        SUM(total_revenue)
    FROM 
        NationOrders
),
RankedNations AS (
    SELECT 
        nation_name, 
        order_count, 
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        NationOrders
)
SELECT 
    n.nation_name,
    COALESCE(r.order_count, 0) AS order_count,
    COALESCE(r.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN r.revenue_rank IS NOT NULL THEN r.revenue_rank 
        ELSE (SELECT MAX(revenue_rank) + 1 FROM RankedNations) 
    END AS revenue_rank
FROM 
    nation n
LEFT JOIN 
    RankedNations r ON n.n_name = r.nation_name
WHERE 
    r.total_revenue > (SELECT AVG(total_revenue) FROM RankedNations WHERE nation_name <> 'Total')
ORDER BY 
    revenue_rank;

