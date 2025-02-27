WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        ts.s_suppkey,
        ts.s_name,
        ts.total_cost
    FROM 
        region r
    JOIN 
        RankedSuppliers ts ON r.r_regionkey = ts.n_regionkey
    WHERE 
        ts.supplier_rank <= 5
),
LargeOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_orderstatus
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    ts.r_regionkey,
    ts.r_name,
    ts.s_suppkey,
    ts.s_name,
    lo.o_orderkey,
    lo.order_value,
    lo.o_orderdate,
    lo.o_orderstatus
FROM 
    TopSuppliers ts
JOIN 
    LargeOrders lo ON ts.s_suppkey = lo.o_custkey
ORDER BY 
    ts.r_regionkey, lo.order_value DESC;
