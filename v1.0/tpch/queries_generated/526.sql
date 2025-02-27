WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        s.n_nationkey,
        ns.n_name,
        ss.s_suppkey,
        ss.s_name,
        ss.total_cost
    FROM 
        SupplierSummary ss
    JOIN 
        nation ns ON ss.s_nationkey = ns.n_nationkey
    WHERE 
        ss.rn <= 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_shippriority
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_shippriority
)
SELECT 
    ts.n_nationkey,
    ts.n_name,
    ts.s_suppkey,
    ts.s_name,
    os.total_revenue,
    os.o_orderstatus,
    os.o_orderdate,
    os.o_shippriority
FROM 
    TopSuppliers ts
LEFT JOIN 
    OrderSummary os ON ts.s_suppkey = os.o_orderkey
WHERE 
    os.total_revenue IS NULL OR os.total_revenue > 50000
ORDER BY 
    ts.n_name, ts.total_cost DESC, os.total_revenue DESC;
