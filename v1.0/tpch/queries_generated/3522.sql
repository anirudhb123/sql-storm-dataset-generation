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
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    tn.n_name AS nation,
    COUNT(DISTINCT ts.s_suppkey) AS top_supplier_count,
    AVG(ss.total_sales) AS avg_top_supplier_sales
FROM 
    nation tn
LEFT JOIN 
    TopSuppliers ts ON tn.n_nationkey = (SELECT s.n_nationkey FROM supplier s WHERE s.s_suppkey = ts.s_suppkey)
LEFT JOIN 
    SupplierSales ss ON ts.s_suppkey = ss.s_suppkey
WHERE 
    ts.sales_rank <= 5
GROUP BY 
    tn.n_name
ORDER BY 
    tn.n_name;
