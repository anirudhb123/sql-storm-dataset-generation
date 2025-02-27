WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),

HighSalesSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        total_sales 
    FROM 
        SupplierSales 
    WHERE 
        sales_rank <= 10
),

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),

PoorPerformingCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(o.order_count, 0) AS order_count,
        COALESCE(o.total_spent, 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders o ON c.c_custkey = o.c_custkey
    WHERE 
        COALESCE(o.order_count, 0) < 5 AND 
        COALESCE(o.total_spent, 0) < 100.00
)

SELECT 
    ps.s_suppkey,
    ps.s_name,
    p.p_partkey,
    p.p_name,
    CASE 
        WHEN c.c_custkey IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    AVG(COALESCE(o.total_spent, 0)) AS avg_spent_per_customer
FROM 
    HighSalesSuppliers ps
JOIN 
    partsupp psup ON ps.s_suppkey = psup.ps_suppkey
JOIN 
    part p ON psup.ps_partkey = p.p_partkey
LEFT JOIN 
    CustomerOrders o ON o.c_custkey IN (SELECT c.c_custkey FROM PoorPerformingCustomers c)
LEFT JOIN 
    customer c ON c.c_custkey = o.c_custkey
WHERE 
    p.p_retailprice > 50 AND 
    p.p_size BETWEEN 10 AND 20
GROUP BY 
    ps.s_suppkey, ps.s_name, p.p_partkey, p.p_name
ORDER BY 
    total_sales DESC, 
    num_customers ASC
LIMIT 50;
