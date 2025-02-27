WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
TopCustomers AS (
    SELECT 
        r.r_name,
        rc.c_nationkey, 
        SUM(ro.total_revenue) AS nation_revenue
    FROM 
        RankedOrders ro
    JOIN 
        nation rc ON ro.c_name = (SELECT c_name FROM customer WHERE c_nationkey = rc.n_nationkey LIMIT 1)
    JOIN 
        region r ON rc.n_regionkey = r.r_regionkey
    WHERE 
        ro.revenue_rank <= 10
    GROUP BY 
        r.r_name, rc.c_nationkey
)
SELECT 
    r.r_name,
    SUM(tc.nation_revenue) AS total_nation_revenue
FROM 
    TopCustomers tc
JOIN 
    region r ON tc.c_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = r.r_name LIMIT 1)
GROUP BY 
    r.r_name
ORDER BY 
    total_nation_revenue DESC;
