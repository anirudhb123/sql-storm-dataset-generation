WITH RECURSIVE RegionSales AS (
    SELECT 
        r.r_name AS region, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        region, 
        total_sales 
    FROM 
        RegionSales 
    WHERE 
        sales_rank <= 5
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
),
SalesByCustomer AS (
    SELECT 
        cus.c_custkey, 
        cus.c_name, 
        COALESCE(ts.total_sales, 0) AS region_sales,
        cus.order_count,
        cus.total_spent
    FROM 
        CustomerOrderSummary cus
    LEFT JOIN TopRegions ts ON ts.region = (SELECT r.r_name FROM region r WHERE r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = cus.c_custkey))
)
SELECT 
    sbc.c_name AS customer_name,
    sbc.order_count,
    sbc.total_spent,
    sbc.region_sales,
    CASE 
        WHEN sbc.total_spent > 10000 THEN 'High'
        WHEN sbc.total_spent > 5000 THEN 'Medium'
        ELSE 'Low'
    END as spending_category
FROM 
    SalesByCustomer sbc
WHERE 
    sbc.region_sales IS NOT NULL
ORDER BY 
    sbc.total_spent DESC, sbc.region_sales DESC;
