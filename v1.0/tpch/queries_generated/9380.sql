WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) as rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
TopOrders AS (
    SELECT 
        ro.mktsegment,
        SUM(ro.o_totalprice) AS TotalSales,
        COUNT(ro.o_orderkey) AS OrderCount
    FROM 
        RankedOrders ro
    WHERE 
        ro.rn <= 10
    GROUP BY 
        ro.mktsegment
)
SELECT 
    r.r_name,
    to.TotalSales,
    to.OrderCount
FROM 
    TopOrders to
JOIN 
    region r ON to.mktsegment = r.r_name
ORDER BY 
    to.TotalSales DESC;
