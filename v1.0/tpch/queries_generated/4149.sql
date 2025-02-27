WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighVolumeSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 10000
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000
)
SELECT 
    s.s_name AS Supplier_Name,
    COALESCE(h.total_available_qty, 0) AS Available_Qty,
    COALESCE(sales.total_sales, 0) AS Total_Sales,
    COUNT(DISTINCT t.c_custkey) AS Number_of_Customers
FROM 
    SupplierSales sales
FULL OUTER JOIN HighVolumeSuppliers h ON sales.s_suppkey = h.s_suppkey
LEFT JOIN TopCustomers t ON t.total_spent > 10000 AND sales.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_shipdate >= '2023-01-01')
)
WHERE 
    COALESCE(sales.sales_rank, 0) <= 10
GROUP BY 
    s.s_name, h.total_available_qty, sales.total_sales
ORDER BY 
    Total_Sales DESC, Supplier_Name ASC;
