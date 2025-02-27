WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
SalesSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
    GROUP BY 
        o.o_orderkey
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    p.p_partkey,
    p.p_name, 
    COALESCE(ss.supplier_sales, 0) AS supplier_sales,
    COALESCE(ss2.total_sales, 0) AS total_sales,
    rs.s_name AS top_supplier,
    rs.rn
FROM 
    part p
LEFT JOIN 
    SupplierSales ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN 
    SalesSummary ss2 ON ss.s_suppkey = ss2.o_orderkey
LEFT JOIN 
    RankedSuppliers rs ON ss.s_suppkey = rs.s_suppkey
WHERE 
    p.p_retailprice > 100.00
ORDER BY 
    total_sales DESC, 
    p.p_name ASC
LIMIT 10;
