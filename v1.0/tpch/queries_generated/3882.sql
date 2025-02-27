WITH SupplierSales AS (
    SELECT 
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        s.s_name
), RankedSuppliers AS (
    SELECT 
        s_name,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales
), ActiveCustomers AS (
    SELECT 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        c.c_name
), RecentOrders AS (
    SELECT 
        o.o_orderkey,
        DATEDIFF(day, o.o_orderdate, GETDATE()) AS days_since_order
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(month, -3, GETDATE())
)
SELECT 
    rs.s_name,
    rs.total_sales,
    ac.total_spent,
    CASE 
        WHEN ac.total_spent IS NULL THEN 'No purchases'
        ELSE 'Active customer'
    END AS customer_status,
    COUNT(ro.o_orderkey) AS recent_order_count
FROM 
    RankedSuppliers rs
LEFT JOIN 
    ActiveCustomers ac ON ac.total_spent > 1000
LEFT JOIN 
    RecentOrders ro ON ro.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_custkey IN (
            SELECT c.c_custkey 
            FROM customer c 
            WHERE c.c_name = ac.c_name
        )
    )
GROUP BY 
    rs.s_name, ac.total_spent
ORDER BY 
    rs.sales_rank;
