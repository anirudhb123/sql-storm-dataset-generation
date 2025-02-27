WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS value_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
top_customers AS (
    SELECT 
        r.r_name AS region,
        rc.c_name AS customer_name,
        rc.total_value
    FROM 
        ranked_orders rc
    JOIN 
        nation n ON rc.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rc.value_rank <= 10
)
SELECT 
    region,
    customer_name,
    total_value
FROM 
    top_customers
ORDER BY 
    region, total_value DESC;
