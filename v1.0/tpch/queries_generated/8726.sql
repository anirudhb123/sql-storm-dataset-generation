WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS brand_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
top_part_brands AS (
    SELECT 
        rp.p_brand,
        rp.p_partkey,
        rp.p_name,
        rp.total_cost
    FROM 
        ranked_parts rp
    WHERE 
        rp.brand_rank <= 5
),
orders_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    t.p_brand,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    SUM(os.total_revenue) AS total_revenue,
    AVG(os.total_revenue) AS avg_revenue_per_order
FROM 
    top_part_brands t
LEFT JOIN 
    orders_summary os ON os.total_revenue IN (
        SELECT 
            total_revenue 
        FROM 
            orders_summary
    )
GROUP BY 
    t.p_brand
ORDER BY 
    total_revenue DESC;
