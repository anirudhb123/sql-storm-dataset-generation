WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2022-12-31'
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue,
        SUM(lo.l_quantity) AS total_quantity
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderstatus,
    ro.o_totalprice,
    ro.o_orderdate,
    ro.o_orderpriority,
    ts.s_name,
    od.revenue,
    od.total_quantity
FROM 
    RankedOrders ro
JOIN 
    OrderDetails od ON ro.o_orderkey = od.l_orderkey
JOIN 
    TopSuppliers ts ON od.l_orderkey IN (SELECT l_orderkey FROM lineitem WHERE l_suppkey = ts.s_suppkey)
WHERE 
    ro.rn <= 10
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice DESC;
