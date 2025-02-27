WITH CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_custkey = c.c_custkey
    WHERE 
        cs.total_sales > 0
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionStats AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(COALESCE(c.a.total_sales, 0)) AS total_region_sales,
        COUNT(DISTINCT c.c_custkey) AS total_customers
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        CustomerSales cs ON c.c_custkey = cs.c_custkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.total_sales,
    ss.s_suppkey,
    ss.s_name,
    ss.avg_supplycost,
    rg.total_region_sales,
    rg.total_customers
FROM 
    TopCustomers tc
JOIN 
    SupplierStats ss ON tc.total_sales > (SELECT AVG(total_sales) FROM CustomerSales WHERE total_sales > 0)
CROSS JOIN 
    (SELECT SUM(total_region_sales) AS total_region_sales, MAX(total_customers) AS total_customers FROM RegionStats) rg
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC, ss.avg_supplycost ASC;
