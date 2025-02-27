WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.nation_name
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name
), 
FinalResults AS (
    SELECT 
        od.o_orderkey,
        od.c_name,
        od.total_revenue,
        od.unique_parts,
        ts.s_name AS top_supplier
    FROM 
        OrderDetails od
    JOIN 
        lineitem l ON od.o_orderkey = l.l_orderkey
    JOIN 
        TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
)
SELECT 
    o.o_orderkey,
    od.c_name,
    od.total_revenue,
    od.unique_parts,
    ts.nation_name AS supplier_nation,
    COUNT(DISTINCT ts.s_suppkey) AS supplier_count,
    AVG(od.total_revenue) AS avg_revenue
FROM 
    FinalResults od
JOIN 
    TopSuppliers ts ON od.top_supplier = ts.s_name
JOIN 
    orders o ON od.o_orderkey = o.o_orderkey
GROUP BY 
    o.o_orderkey, od.c_name, ts.nation_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
