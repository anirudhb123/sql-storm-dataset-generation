WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders AS o
    JOIN 
        customer AS c ON o.o_custkey = c.c_custkey
    JOIN 
        nation AS n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region AS r ON n.n_regionkey = r.r_regionkey
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, r.r_name
),
top_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.c_name,
        o.region,
        o.total_revenue
    FROM 
        ranked_orders AS o
    WHERE 
        o.revenue_rank <= 5
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.c_name,
    t.region,
    t.total_revenue,
    COUNT(DISTINCT l.l_partkey) AS unique_parts,
    AVG(l.l_quantity) AS avg_quantity
FROM 
    top_orders AS t
JOIN 
    lineitem AS l ON t.o_orderkey = l.l_orderkey
GROUP BY 
    t.o_orderkey, t.o_orderdate, t.c_name, t.region, t.total_revenue
ORDER BY 
    t.total_revenue DESC;
