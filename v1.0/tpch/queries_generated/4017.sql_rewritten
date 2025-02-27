WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
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
    ns.n_name AS nation, 
    COUNT(DISTINCT ts.s_suppkey) AS supplier_count, 
    AVG(ss.total_sales) AS avg_sales
FROM 
    nation ns
LEFT JOIN 
    TopSuppliers ts ON ns.n_nationkey = (SELECT s.s_nationkey 
                                           FROM supplier s 
                                           WHERE s.s_suppkey = ts.s_suppkey)
LEFT JOIN 
    SupplierSales ss ON ts.s_suppkey = ss.s_suppkey
WHERE 
    ts.sales_rank <= 10
GROUP BY 
    ns.n_name
HAVING 
    COUNT(DISTINCT ts.s_suppkey) > 1
ORDER BY 
    avg_sales DESC, 
    supplier_count DESC;