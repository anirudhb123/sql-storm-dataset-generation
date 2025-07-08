
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(CASE WHEN o.o_orderstatus = 'O' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
), 
RankedSales AS (
    SELECT 
        region_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
), 
TopRegions AS (
    SELECT * FROM RankedSales WHERE sales_rank <= 5
), 
CustomerAnalysis AS (
    SELECT 
        c.c_name,
        c.c_acctbal * 0.9 AS adjusted_balance,
        COUNT(DISTINCT o.o_orderkey) AS customer_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name, c.c_acctbal
    HAVING 
        SUM(o.o_totalprice) > 1000
), 
MergedAnalysis AS (
    SELECT 
        tr.region_name,
        tr.total_sales,
        ca.c_name,
        ca.adjusted_balance,
        COALESCE(tr.order_count, 0) AS region_orders,
        COALESCE(ca.customer_orders, 0) AS orders_from_customer
    FROM 
        TopRegions tr
    FULL OUTER JOIN 
        CustomerAnalysis ca ON tr.region_name LIKE '%North%' AND 
                             ca.c_name IS NOT NULL
)
SELECT 
    COALESCE(region_name, 'Unknown Region') AS region,
    COALESCE(total_sales, 0) AS total_region_sales,
    COALESCE(c_name, 'Anonymous Customer') AS customer_name,
    CASE 
        WHEN adjusted_balance IS NULL THEN 'N/A' 
        ELSE adjusted_balance::TEXT
    END AS adjusted_customer_balance,
    region_orders,
    orders_from_customer
FROM 
    MergedAnalysis
ORDER BY 
    total_region_sales DESC, region, customer_name;
