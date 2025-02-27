WITH PartDetails AS (
    SELECT 
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_available,
        AVG(p.p_retailprice) AS avg_retail_price,
        STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', s.s_address), '; ') AS suppliers_info
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_name, p.p_brand, p.p_type
),
OrderSummary AS (
    SELECT 
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    pd.p_name,
    pd.p_brand,
    pd.p_type,
    pd.total_available,
    pd.avg_retail_price,
    os.total_orders,
    os.total_revenue,
    os.total_revenue / NULLIF(os.total_orders, 0) AS avg_revenue_per_order,
    ROW_NUMBER() OVER (ORDER BY pd.total_available DESC) AS rank_by_availability
FROM 
    PartDetails pd
JOIN 
    OrderSummary os ON os.total_orders > 0 
WHERE 
    pd.avg_retail_price > 50.00
ORDER BY 
    pd.avg_retail_price DESC, rank_by_availability;
