WITH RankedOrders AS (
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
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        o.o_orderkey, c.c_mktsegment
),
TopSegments AS (
    SELECT 
        c.c_mktsegment,
        SUM(total_revenue) AS segment_revenue
    FROM 
        RankedOrders
    JOIN 
        customer c ON RankedOrders.o_orderkey = c.c_custkey
    WHERE 
        revenue_rank <= 5
    GROUP BY 
        c.c_mktsegment
)
SELECT 
    r.r_name,
    t.segment_revenue
FROM 
    TopSegments t
JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_mktsegment = t.c_mktsegment LIMIT 1)
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
ORDER BY 
    t.segment_revenue DESC;