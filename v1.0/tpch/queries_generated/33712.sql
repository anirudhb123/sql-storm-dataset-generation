WITH RECURSIVE SalesCTE AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSales AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        total_sales
    FROM 
        SalesCTE
    WHERE 
        sales_rank <= 10
),
SupplierSales AS (
    SELECT 
        s.s_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS supplier_sales
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_name
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.total_sales,
    s.s_name,
    s.supplier_sales
FROM 
    TopSales t
LEFT JOIN 
    SupplierSales s ON t.total_sales > s.supplier_sales
WHERE 
    EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_orderkey = t.o_orderkey AND l.l_returnflag = 'R'
    )
ORDER BY 
    t.o_orderdate DESC,
    t.total_sales DESC
LIMIT 50;
