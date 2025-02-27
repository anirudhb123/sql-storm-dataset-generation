WITH SalesSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        t.custkey,
        t.c_name,
        t.total_sales,
        t.order_count,
        r.r_name AS region_name
    FROM 
        SalesSummary t
    JOIN 
        nation n ON t.custkey = n.n_nationkey -- Assume custkey maps to nation key for this case
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        t.sales_rank <= 10
)
SELECT 
    tc.c_name,
    tc.total_sales,
    tc.order_count,
    COALESCE(NULLIF(MAX(l.l_shipdate), '1900-01-01'), 'N/A') AS last_ship_date,
    CASE 
        WHEN tc.total_sales > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    TopCustomers tc
LEFT JOIN 
    lineitem l ON tc.custkey = l.l_suppkey -- Joining back to lineitem for shipping info
GROUP BY 
    tc.c_name, tc.total_sales, tc.order_count
ORDER BY 
    total_sales DESC;
