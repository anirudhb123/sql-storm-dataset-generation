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
        r.r_name AS region_name, 
        n.n_name AS nation_name, 
        rs.s_name AS supplier_name, 
        rs.total_supplycost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
),
OrderStats AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderpriority, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderpriority
)
SELECT 
    ts.region_name, 
    ts.nation_name, 
    ts.supplier_name, 
    os.o_orderpriority, 
    SUM(os.revenue) AS total_revenue
FROM 
    TopSuppliers ts
JOIN 
    OrderStats os ON ts.supplier_name = os.o_orderpriority
GROUP BY 
    ts.region_name, 
    ts.nation_name, 
    ts.supplier_name, 
    os.o_orderpriority
HAVING 
    SUM(os.revenue) > 10000
ORDER BY 
    ts.region_name, 
    ts.nation_name, 
    SUM(os.revenue) DESC;
