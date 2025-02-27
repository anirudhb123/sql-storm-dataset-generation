WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
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
        r.r_name AS region_name,
        rs.s_name AS supplier_name,
        rs.total_supplycost
    FROM 
        RankedSuppliers rs
    JOIN 
        region r ON rs.s_nationkey = r.r_regionkey
    WHERE 
        rs.supplier_rank <= 3
)

SELECT 
    c.c_name AS customer_name,
    o.o_orderkey,
    o.o_orderdate,
    ts.region_name,
    ts.supplier_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    c.c_name, o.o_orderkey, o.o_orderdate, ts.region_name, ts.supplier_name
ORDER BY 
    ts.region_name, total_price DESC;
