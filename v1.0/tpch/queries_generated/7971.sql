WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TotalOrderValue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2022-12-31'
    GROUP BY 
        o.o_orderkey
),
TopOrders AS (
    SELECT 
        o.c_custkey,
        COUNT(*) AS order_count,
        SUM(t.order_value) AS total_order_value
    FROM 
        TotalOrderValue t
    JOIN 
        orders o ON t.o_orderkey = o.o_orderkey
    GROUP BY 
        o.c_custkey
    HAVING 
        SUM(t.order_value) > 10000
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ts.s_suppkey) AS num_suppliers,
    SUM(ts.total_cost) AS total_supplier_cost,
    MAX(ts.rank) AS max_rank,
    SUM(TO.total_order_value) AS total_order_value
FROM 
    RankedSuppliers ts
JOIN 
    nation n ON ts.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    TopOrders TO ON TO.c_custkey = ts.s_nationkey
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
