WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.rnk = 1
),
SupplierPartRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        spr.s_suppkey,
        spr.s_name,
        spr.supplier_revenue,
        ROW_NUMBER() OVER (ORDER BY spr.supplier_revenue DESC) AS supplier_rank
    FROM 
        SupplierPartRevenue spr
    WHERE 
        spr.supplier_revenue > 100000
)
SELECT 
    to.o_orderdate,
    to.total_revenue,
    ts.s_name,
    ts.supplier_revenue
FROM 
    TopOrders to
JOIN 
    TopSuppliers ts ON ts.supplier_rank <= 5
ORDER BY 
    to.total_revenue DESC, ts.supplier_revenue DESC;
