WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    tr.r_name AS region_name,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(ro.revenue) AS total_revenue,
    AVG(tr.total_supply_cost) AS avg_supply_cost
FROM 
    RankedOrders ro
JOIN 
    TopRegions tr ON ro.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey)
GROUP BY 
    tr.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
