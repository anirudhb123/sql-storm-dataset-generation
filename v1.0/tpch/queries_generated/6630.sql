WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderpriority
    FROM 
        RankedOrders ro
    WHERE 
        ro.OrderRank <= 10
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS Revenue
    FROM 
        lineitem lo
    JOIN 
        TopOrders to ON lo.l_orderkey = to.o_orderkey
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.o_totalprice,
    to.o_orderpriority,
    od.Revenue
FROM 
    TopOrders to
LEFT JOIN 
    OrderDetails od ON to.o_orderkey = od.l_orderkey
ORDER BY 
    to.o_totalprice DESC, 
    to.o_orderdate ASC;
