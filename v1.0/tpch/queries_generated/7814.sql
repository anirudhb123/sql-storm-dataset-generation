WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        n.n_name,
        r.r_name 
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.order_rank <= 5
),
SalesSummary AS (
    SELECT 
        to.n_name AS nation,
        to.r_name AS region,
        SUM(to.o_totalprice) AS total_sales,
        COUNT(to.o_orderkey) AS order_count
    FROM 
        TopOrders to
    GROUP BY 
        to.n_name, to.r_name
)
SELECT 
    ss.nation,
    ss.region,
    ss.total_sales,
    ss.order_count,
    AVG(lp.l_extendedprice) AS avg_line_price,
    SUM(lp.l_discount) AS total_discount
FROM 
    SalesSummary ss
JOIN 
    lineitem lp ON EXISTS (
        SELECT 1 
        FROM orders o 
        WHERE o.o_orderkey IN (SELECT o_orderkey FROM TopOrders) 
        AND o.o_orderkey = lp.l_orderkey
    )
GROUP BY 
    ss.nation, ss.region
ORDER BY 
    ss.total_sales DESC, 
    ss.order_count DESC;
