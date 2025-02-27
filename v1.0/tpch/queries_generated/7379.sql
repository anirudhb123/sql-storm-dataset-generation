WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
top_nations AS (
    SELECT 
        n.n_name,
        SUM(r.total_revenue) AS nation_revenue
    FROM 
        ranked_orders r
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.revenue_rank <= 3
    GROUP BY 
        n.n_name
)
SELECT 
    n.n_name,
    n.nation_revenue,
    RANK() OVER (ORDER BY n.nation_revenue DESC) AS revenue_rank
FROM 
    top_nations n
ORDER BY 
    revenue_rank;
