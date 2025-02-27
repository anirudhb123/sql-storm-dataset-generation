WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TotalOrders AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_custkey
)
SELECT 
    reg.r_name AS region,
    na.n_name AS nation,
    s.s_name AS supplier_name,
    o.order_count,
    rs.total_cost
FROM 
    RankedSuppliers rs
JOIN 
    nation na ON rs.s_nationkey = na.n_nationkey
JOIN 
    region reg ON na.n_regionkey = reg.r_regionkey
JOIN 
    TotalOrders o ON na.n_nationkey = o.o_nationkey
WHERE 
    rs.rank <= 5
ORDER BY 
    reg.r_name, na.n_name, rs.total_cost DESC;
