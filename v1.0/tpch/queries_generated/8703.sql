WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey
),
RecentOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.net_revenue,
        c.c_name,
        c.c_mktsegment
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_custkey = c.c_custkey
    WHERE 
        ro.rn = 1 AND 
        ro.o_orderdate >= DATEADD(month, -6, GETDATE())
),
SupplierStats AS (
    SELECT 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.net_revenue,
    ro.c_name,
    ro.c_mktsegment,
    ss.s_name AS top_supplier,
    ss.total_supply_cost
FROM 
    RecentOrders ro
JOIN 
    (SELECT s_name, ROW_NUMBER() OVER (ORDER BY total_supply_cost DESC) AS rnk 
     FROM SupplierStats) ss ON ss.rnk = 1
ORDER BY 
    ro.o_orderdate DESC;
