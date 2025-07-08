WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY DATE_TRUNC('month', o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.total_revenue,
    tc.c_custkey,
    tc.c_name,
    tc.order_count,
    tc.total_spent
FROM 
    ranked_orders r
JOIN 
    top_customers tc ON r.o_orderkey IN (
        SELECT 
            o.o_orderkey 
        FROM 
            orders o 
        JOIN 
            customer c ON o.o_custkey = c.c_custkey 
        WHERE 
            c.c_custkey = tc.c_custkey
    )
WHERE 
    r.revenue_rank <= 5
ORDER BY 
    r.o_orderdate DESC, r.total_revenue DESC;
