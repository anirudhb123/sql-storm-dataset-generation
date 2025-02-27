WITH RECURSIVE PriceHistory AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        CAST(NULLIF(ps.ps_supplycost, 0) AS decimal(12, 2)) * 1.1 AS adjusted_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 0
), AggregatedData AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'O')
    GROUP BY 
        n.n_nationkey
), RankedNations AS (
    SELECT 
        nation_name,
        total_revenue,
        orders_count,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        AggregatedData
)
SELECT 
    r.nation_name,
    r.total_revenue,
    r.orders_count,
    ph.adjusted_cost,
    CASE
        WHEN r.orders_count > 100 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS order_volume_category,
    CASE 
        WHEN COUNT(DISTINCT n.n_nationkey) IS NULL THEN 'No Nation Data'
        ELSE 'Nation Exists'
    END AS nation_status
FROM 
    RankedNations r
LEFT JOIN 
    PriceHistory ph ON ph.p_partkey = (
        SELECT 
            p_partkey 
        FROM 
            PriceHistory 
        WHERE 
            rn = 1 
        LIMIT 1
    )
WHERE 
    r.revenue_rank <= 5
GROUP BY 
    r.nation_name, r.total_revenue, r.orders_count, ph.adjusted_cost
HAVING 
    SUM(ph.adjusted_cost) IS NOT NULL
ORDER BY 
    r.total_revenue DESC, r.nation_name ASC;
