WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 10
),
SupplierInfo AS (
    SELECT 
        ps.ps_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_suppkey, s.s_name
)
SELECT 
    tra.o_orderkey,
    tra.o_orderdate,
    tra.total_revenue,
    si.s_name,
    si.total_supply_cost
FROM 
    TopRevenueOrders tra
JOIN 
    SupplierInfo si ON tra.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = tra.o_orderkey ORDER BY l.l_extendedprice DESC LIMIT 1)
ORDER BY 
    tra.total_revenue DESC, si.total_supply_cost ASC;
