WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        N.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY N.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation N ON s.s_nationkey = N.n_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.s_acctbal, 
        rs.nation_name
    FROM 
        RankedSupplier rs
    WHERE 
        rs.rank <= 3
),
ProductSales AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierSales AS (
    SELECT 
        ts.s_suppkey, 
        ts.s_name, 
        ps.total_revenue
    FROM 
        TopSuppliers ts
    JOIN 
        partsupp ps ON ts.s_suppkey = ps.ps_suppkey
    JOIN 
        ProductSales p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    ts.s_suppkey, 
    ts.s_name, 
    SUM(s.total_revenue) AS total_sales
FROM 
    SupplierSales s
JOIN 
    TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
GROUP BY 
    ts.s_suppkey, ts.s_name
ORDER BY 
    total_sales DESC
LIMIT 10;
