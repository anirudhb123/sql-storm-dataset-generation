WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY YEAR(o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRegions AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    r.region_name,
    r.nation_name,
    SUM(r.total_supply_cost) AS total_cost,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    AVG(ro.total_revenue) AS average_order_value
FROM 
    TopRegions r
LEFT JOIN 
    RankedOrders ro ON ro.o_orderdate >= DATEADD(YEAR, -1, CURRENT_DATE)
GROUP BY 
    r.region_name, r.nation_name
HAVING 
    SUM(r.total_supply_cost) > 100000
ORDER BY 
    total_cost DESC, average_order_value DESC
LIMIT 10;
