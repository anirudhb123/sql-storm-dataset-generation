WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        r.r_name,
        s.total_supply_value
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.supplier_rank <= 3
)
SELECT 
    c.c_name,
    o.o_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    ts.s_name AS top_supplier,
    r.r_name AS region_name
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    TopSuppliers ts ON ss.s_name = ts.top_supplier
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate >= DATE '2023-01-01'
    AND o.o_orderdate < DATE '2023-12-31'
GROUP BY 
    c.c_name, o.o_orderkey, ts.top_supplier, r.r_name
ORDER BY 
    total_revenue DESC;
