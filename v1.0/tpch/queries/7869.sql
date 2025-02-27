WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
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
        o.o_orderdate BETWEEN DATE '1994-01-01' AND DATE '1994-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, c.c_nationkey
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(ro.total_revenue) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_name = ro.c_name)
    WHERE 
        ro.revenue_rank <= 5
    GROUP BY 
        n.n_name
)
SELECT 
    rn.n_name,
    rn.total_revenue,
    RANK() OVER (ORDER BY rn.total_revenue DESC) AS revenue_rank
FROM 
    TopNations rn
ORDER BY 
    rn.total_revenue DESC;
