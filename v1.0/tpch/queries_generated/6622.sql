WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
top_customers AS (
    SELECT
        r.r_name,
        rc.revenue_rank,
        rc.o_orderkey,
        rc.o_orderdate,
        rc.c_name,
        rc.total_revenue
    FROM 
        ranked_orders rc
    JOIN 
        nation n ON n.n_nationkey = c.c_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rc.revenue_rank <= 5
)
SELECT 
    r.r_name AS region,
    COUNT(tc.o_orderkey) AS number_of_orders,
    SUM(tc.total_revenue) AS total_revenue,
    AVG(tc.total_revenue) AS average_order_value
FROM 
    top_customers tc
JOIN 
    nation n ON n.n_nationkey = tc.c_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;
