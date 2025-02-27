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
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),

TopSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        total_sales,
        order_count,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales
),

PartPopularity AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(l.l_orderkey) AS order_count,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        COUNT(l.l_orderkey) > 10
)

SELECT 
    ts.s_name AS Supplier_Name,
    ts.total_sales AS Total_Sales,
    ts.order_count AS Order_Count,
    pp.p_name AS Popular_Part,
    pp.order_count AS Part_Order_Count,
    pp.avg_price AS Avg_Part_Price
FROM 
    TopSuppliers ts
LEFT JOIN 
    PartPopularity pp ON ts.s_suppkey = (SELECT ps.ps_suppkey 
                                          FROM partsupp ps 
                                          WHERE ps.ps_partkey = pp.p_partkey 
                                          LIMIT 1)
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.total_sales DESC, pp.avg_price ASC;
