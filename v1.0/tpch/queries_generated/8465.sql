WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.total_revenue,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.order_rank <= 10
)
SELECT 
    to.region_name,
    COUNT(to.o_orderkey) AS order_count,
    SUM(to.total_revenue) AS total_revenue,
    AVG(to.total_revenue) AS avg_revenue
FROM 
    TopOrders to
GROUP BY 
    to.region_name
ORDER BY 
    total_revenue DESC;
