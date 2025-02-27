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
        o.o_orderstatus = 'F' AND 
        l.l_shipdate >= DATE '2023-01-01' AND 
        l.l_shipdate < DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        TOP (5) WITH TIES c.c_name,
        total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_name = ro.c_name)
    JOIN 
        region r ON r.r_regionkey = n.n_regionkey
    WHERE 
        ro.revenue_rank <= 5
)
SELECT 
    region,
    nation,
    c_name,
    SUM(total_revenue) AS total_revenue
FROM 
    TopCustomers
GROUP BY 
    region, nation, c_name
ORDER BY 
    region, nation, total_revenue DESC;
