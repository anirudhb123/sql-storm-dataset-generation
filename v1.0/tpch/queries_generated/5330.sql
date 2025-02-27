WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        CUME_DIST() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        ro.total_revenue
    FROM 
        customer c
    JOIN 
        RankedOrders ro ON c.c_custkey = ro.o_custkey
    WHERE 
        ro.revenue_rank <= 0.1
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT tc.c_custkey) AS num_top_customers,
    AVG(tc.total_revenue) AS avg_revenue
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    TopCustomers tc ON tc.o_custkey = c.c_custkey
GROUP BY 
    r.r_name
ORDER BY 
    avg_revenue DESC;
