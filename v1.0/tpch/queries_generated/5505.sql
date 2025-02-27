WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        r.r_name AS region_name
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.revenue_rank <= 10
)
SELECT 
    to.o_orderkey,
    to.o_orderstatus,
    to.o_totalprice,
    to.o_orderdate,
    to.c_name AS customer_name,
    COUNT(l.l_orderkey) AS item_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
FROM 
    TopOrders to
JOIN 
    lineitem l ON to.o_orderkey = l.l_orderkey
GROUP BY 
    to.o_orderkey, to.o_orderstatus, to.o_totalprice, to.o_orderdate, to.c_name
ORDER BY 
    net_revenue DESC;
