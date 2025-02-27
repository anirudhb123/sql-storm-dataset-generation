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
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        s_suppkey 
    FROM 
        SupplierSales 
    WHERE 
        total_sales > (
            SELECT 
                AVG(total_sales) 
            FROM 
                SupplierSales
        )
),
CustomerRegion AS (
    SELECT 
        c.c_custkey, 
        r.r_regionkey
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.r_regionkey,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(ss.total_sales) AS total_sales_by_region,
    AVG(co.order_count) AS avg_order_count_per_customer
FROM 
    CustomerRegion cr
LEFT JOIN 
    CustomerOrderCount co ON cr.c_custkey = co.c_custkey
LEFT JOIN 
    SupplierSales ss ON ss.s_suppkey IN (SELECT * FROM HighValueSuppliers)
GROUP BY 
    cr.r_regionkey
HAVING 
    SUM(ss.total_sales) IS NOT NULL 
    AND COUNT(DISTINCT c.c_custkey) > 0
ORDER BY 
    total_sales_by_region DESC;
