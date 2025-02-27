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
        l.l_shipdate >= '2023-01-01' 
        AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ss.total_sales,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        supplier s
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
),
FinalReport AS (
    SELECT 
        co.c_custkey, 
        co.c_name, 
        co.order_count, 
        co.total_spent, 
        rs.s_name AS top_supplier, 
        rs.total_sales AS supplier_sales
    FROM 
        CustomerOrders co
    LEFT JOIN 
        RankedSuppliers rs ON co.total_spent = (
            SELECT MAX(total_spent) 
            FROM CustomerOrders 
            WHERE customer.c_custkey = co.c_custkey
        )
)
SELECT 
    fr.*, 
    CASE 
        WHEN fr.total_spent IS NULL THEN 'No Orders'
        WHEN fr.total_spent < 1000 THEN 'Low Value'
        ELSE 'High Value'
    END AS customer_value,
    COALESCE(fr.supplier_sales, 0) AS supplier_sales_or_zero
FROM 
    FinalReport fr
ORDER BY 
    fr.order_count DESC, fr.total_spent DESC;
