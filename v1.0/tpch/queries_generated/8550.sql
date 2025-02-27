WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
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
        r.r_name,
        n.n_name,
        rs.s_suppkey,
        rs.s_name,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
),
OrderAmounts AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        l.l_suppkey
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
)
SELECT 
    ts.r_name AS region,
    ts.n_name AS nation,
    ts.s_suppkey,
    ts.s_name,
    COUNT(oa.o_orderkey) AS total_orders,
    SUM(oa.o_totalprice) AS total_revenue
FROM 
    TopSuppliers ts
LEFT JOIN 
    OrderAmounts oa ON ts.s_suppkey = oa.l_suppkey
GROUP BY 
    ts.r_name, ts.n_name, ts.s_suppkey, ts.s_name
ORDER BY 
    total_revenue DESC;
