WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_within_nation
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_custkey, c.c_name
),
top_customers AS (
    SELECT 
        r.r_name,
        COUNT(*) AS number_of_top_customers,
        SUM(to.total_line_value) AS total_revenue
    FROM 
        ranked_orders to
    JOIN 
        nation n ON to.c_custkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        to.rank_within_nation <= 10
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    tc.number_of_top_customers,
    tc.total_revenue
FROM 
    region r
LEFT JOIN 
    top_customers tc ON r.r_name = tc.r_name
ORDER BY 
    tc.total_revenue DESC, 
    tc.number_of_top_customers DESC;
