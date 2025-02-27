WITH CTE_SupplierSales AS (
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
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
CTE_AverageSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales
    FROM 
        CTE_SupplierSales
),
CTE_FilteredSuppliers AS (
    SELECT 
        supp.s_suppkey, 
        supp.s_name, 
        supp.total_sales,
        supp.order_count
    FROM 
        CTE_SupplierSales supp
    WHERE 
        supp.total_sales > (SELECT avg_sales FROM CTE_AverageSales)
)
SELECT 
    r.r_name,
    ns.n_name,
    COUNT(DISTINCT fs.s_suppkey) AS supplier_count,
    SUM(fs.total_sales) AS total_sales
FROM 
    region r
LEFT JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    CTE_FilteredSuppliers fs ON ns.n_nationkey = 
        (SELECT s.n_nationkey FROM supplier s WHERE s.s_suppkey = fs.s_suppkey)
GROUP BY 
    r.r_name, ns.n_name
HAVING 
    SUM(fs.total_sales) IS NOT NULL
ORDER BY 
    total_sales DESC;
