
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND
        l.l_shipdate >= DATE '1997-01-01' 
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
),
Regions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    rs.r_name,
    ts.s_name,
    ts.total_sales,
    ts.order_count,
    rg.supplier_count
FROM 
    TopSuppliers ts
JOIN 
    Regions rg ON ts.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (
        SELECT p.p_partkey FROM part p WHERE p.p_size > 10
    ))
LEFT JOIN 
    region rs ON ts.s_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey IN (
        SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = rg.n_regionkey
    ))
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.total_sales DESC, rs.r_name;
