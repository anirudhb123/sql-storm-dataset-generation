WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.n_nationkey,
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rn <= 3
),
SalesData AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ts.n_nationkey,
    ts.s_name,
    ts.total_supply_cost,
    sd.c_name,
    sd.total_sales
FROM 
    TopSuppliers ts
JOIN 
    SalesData sd ON ts.n_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'USA') 
ORDER BY 
    ts.total_supply_cost DESC, 
    sd.total_sales DESC;
