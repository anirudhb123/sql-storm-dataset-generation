
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        rs.nation_name
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.supplier_rank <= 5
),
SalesData AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    INNER JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        l.l_partkey
),
PartSupplierSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(sd.total_sales) AS total_sales_for_part,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        SalesData sd ON ps.ps_partkey = sd.l_partkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(pss.total_sales_for_part, 0) AS total_sales,
    COALESCE(pss.supplier_count, 0) AS supplier_count,
    rs.s_name AS top_supplier_name
FROM 
    part p
LEFT JOIN 
    PartSupplierSales pss ON p.p_partkey = pss.ps_partkey
LEFT JOIN 
    TopSuppliers rs ON rs.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey
        ORDER BY ps.ps_supplycost 
        LIMIT 1
    )
ORDER BY 
    p.p_partkey;
