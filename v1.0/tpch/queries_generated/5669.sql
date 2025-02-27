WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, c.c_mktsegment
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        ra.total_revenue
    FROM 
        ranked_orders ra
    JOIN 
        customer c ON ra.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = c.c_custkey)
    WHERE 
        ra.revenue_rank <= 10
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.c_mktsegment,
    tc.total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS orders_count
FROM 
    top_customers tc
JOIN 
    orders o ON o.o_custkey = tc.c_custkey
GROUP BY 
    tc.c_custkey, tc.c_name, tc.c_mktsegment, tc.total_revenue
ORDER BY 
    tc.total_revenue DESC;
