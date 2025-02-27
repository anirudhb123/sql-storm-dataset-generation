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
        o.o_orderstatus = 'F'
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
), CustomerOrders AS (
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
    HAVING 
        COUNT(o.o_orderkey) > 0
)
SELECT 
    rs.s_name,
    rs.total_sales,
    rs.order_count,
    co.c_name AS top_customer,
    co.total_spent,
    rs.sales_rank
FROM 
    RankedSuppliers rs
LEFT JOIN 
    (SELECT 
         s.s_suppkey, 
         c.c_name, 
         SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_spending
     FROM 
         lineitem l
     JOIN 
         orders o ON l.l_orderkey = o.o_orderkey
     JOIN 
         partsupp ps ON l.l_partkey = ps.ps_partkey
     JOIN 
         supplier s ON ps.ps_suppkey = s.s_suppkey
     JOIN 
         customer c ON o.o_custkey = c.c_custkey
     WHERE 
         l.l_returnflag = 'N'
     GROUP BY 
         s.s_suppkey, c.c_name) AS top_customers
ON 
    rs.s_suppkey = top_customers.s_suppkey
JOIN 
    CustomerOrders co ON co.order_count = 
    (SELECT MAX(order_count) FROM CustomerOrders WHERE c_custkey = co.c_custkey)
WHERE 
    rs.sales_rank <= 5
ORDER BY 
    rs.sales_rank;
