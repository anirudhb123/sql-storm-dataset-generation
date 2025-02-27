WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
TopSuppliers AS (
    SELECT 
        s.s_nationkey, 
        s.s_name, 
        s.total_supplycost
    FROM 
        RankedSuppliers s
    WHERE 
        s.rank <= 5
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
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
), 
NationSales AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        SUM(sd.total_sales) AS total_sales_per_nation
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        SalesData sd ON c.c_custkey = sd.c_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
)

SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    ts.s_name AS top_supplier,
    ns.total_sales_per_nation
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    TopSuppliers ts ON n.n_nationkey = ts.s_nationkey
JOIN 
    NationSales ns ON n.n_nationkey = ns.n_nationkey
WHERE 
    ns.total_sales_per_nation > 10000
ORDER BY 
    r.r_name, n.n_name, ns.total_sales_per_nation DESC;
