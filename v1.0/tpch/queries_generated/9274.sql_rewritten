WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_supply_cost,
        RANK() OVER (ORDER BY s.total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierSummary s
    WHERE 
        s.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierSummary)
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.total_revenue,
    ts.s_suppkey,
    ts.s_name,
    ts.total_supply_cost
FROM 
    RankedOrders ro
JOIN 
    TopSuppliers ts ON ro.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = ts.s_suppkey)
WHERE 
    ro.revenue_rank <= 10 AND ts.supplier_rank <= 5
ORDER BY 
    ro.o_orderdate DESC, ro.total_revenue DESC;