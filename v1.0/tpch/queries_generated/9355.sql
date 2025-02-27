WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1993-01-01' AND o.o_orderdate < DATE '1994-01-01'
    GROUP BY 
        o.o_orderkey, c.c_mktsegment
),
top_segments AS (
    SELECT 
        c.c_mktsegment,
        SUM(r.revenue) AS total_revenue
    FROM 
        ranked_orders r
    JOIN 
        customer c ON EXISTS (SELECT 1 FROM ranked_orders WHERE o_orderkey = r.o_orderkey)
    WHERE 
        r.rank <= 10
    GROUP BY 
        c.c_mktsegment
)
SELECT 
    ps.p_partkey,
    p.p_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
    ts.total_revenue
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    top_segments ts ON EXISTS (SELECT 1 FROM lineitem l WHERE l.l_partkey = p.p_partkey)
GROUP BY 
    ps.p_partkey, p.p_name, ts.total_revenue
ORDER BY 
    total_cost DESC, p.p_name;
