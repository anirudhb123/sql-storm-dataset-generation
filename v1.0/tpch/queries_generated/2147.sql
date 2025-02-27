WITH OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, c.c_name, c.c_nationkey
),
RankedOrders AS (
    SELECT 
        od.*, 
        RANK() OVER (PARTITION BY od.c_nationkey ORDER BY od.total_revenue DESC) AS order_rank
    FROM 
        OrderDetails od
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    AVG(ro.total_revenue) AS avg_revenue,
    MAX(ro.total_revenue) AS max_revenue,
    MIN(ro.total_revenue) AS min_revenue
FROM 
    RankedOrders ro
LEFT JOIN 
    nation n ON ro.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ro.order_rank <= 5
GROUP BY 
    r.r_name
ORDER BY 
    avg_revenue DESC
UNION ALL
SELECT 
    'Total' AS r_name,
    COUNT(DISTINCT o.o_orderkey),
    AVG(total_revenue),
    MAX(total_revenue),
    MIN(total_revenue)
FROM 
    OrderDetails o;
