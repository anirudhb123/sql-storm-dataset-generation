WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
),
supplier_avg_cost AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_partkey) AS items_count,
        MAX(l.l_extendedprice) AS max_item_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.o_orderkey,
    r.total_revenue,
    c.c_name,
    COALESCE(s.avg_supply_cost, 0) AS avg_supply_cost,
    o.items_count,
    o.max_item_price,
    CASE 
        WHEN r.revenue_rank <= 10 THEN 'Top 10 Revenue'
        ELSE 'Other'
    END AS revenue_tier
FROM 
    ranked_orders r
LEFT JOIN 
    top_customers c ON r.o_orderkey = c.c_custkey
LEFT JOIN 
    supplier_avg_cost s ON s.ps_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = c.c_custkey LIMIT 1)
JOIN 
    order_summary o ON r.o_orderkey = o.o_orderkey
WHERE 
    r.total_revenue IS NOT NULL
ORDER BY 
    r.total_revenue DESC, c.c_name;
