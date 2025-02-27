WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey
),
TopRevenueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        ro.total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        orders o ON ro.o_orderkey = o.o_orderkey
    WHERE 
        ro.revenue_rank <= 10
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    to.o_orderkey,
    to.total_revenue,
    sr.s_suppkey,
    sr.total_supply_cost
FROM 
    TopRevenueOrders to
JOIN 
    SupplierRevenue sr ON to.o_orderkey = sr.s_suppkey
WHERE 
    sr.total_supply_cost > 10000
ORDER BY 
    to.total_revenue DESC, sr.total_supply_cost ASC;
