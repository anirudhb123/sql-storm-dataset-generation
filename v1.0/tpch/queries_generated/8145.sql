WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01'
        AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(ro.total_revenue) AS nation_revenue
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = ro.o_custkey)
    WHERE 
        ro.revenue_rank <= 5
    GROUP BY 
        n.n_name
)
SELECT 
    tn.n_name,
    tn.nation_revenue
FROM 
    TopNations tn
ORDER BY 
    tn.nation_revenue DESC
LIMIT 10;
