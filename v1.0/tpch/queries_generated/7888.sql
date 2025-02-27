WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        c.c_acctbal,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, c.c_acctbal
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT ro.o_orderkey) AS total_orders,
        AVG(ro.total_revenue) AS avg_revenue
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        RankedOrders ro ON c.c_custkey = ro.o_orderkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    tn.n_name,
    tn.total_orders,
    tn.avg_revenue,
    r.r_name AS region_name
FROM 
    TopNations tn
JOIN 
    region r ON tn.n_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
WHERE 
    tn.avg_revenue > 10000
ORDER BY 
    tn.avg_revenue DESC, tn.total_orders DESC;
