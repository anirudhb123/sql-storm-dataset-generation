WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(CASE WHEN ps.ps_availqty < 100 THEN ps.ps_supplycost ELSE NULL END) AS avg_cost_low_supply,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionSales AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_sales,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name, r.r_name
),
SalesSummary AS (
    SELECT 
        rs.region_name,
        rs.customer_count,
        rs.total_sales,
        COALESCE(SUM(ss.total_supply_cost), 0) AS total_supplier_cost,
        STRING_AGG(CONCAT(ss.s_name, ': ', ss.total_orders), '; ') AS supplier_orders
    FROM 
        RegionSales rs
    LEFT JOIN 
        SupplierStats ss ON ss.total_orders > 0
    GROUP BY 
        rs.region_name, rs.customer_count, rs.total_sales
)

SELECT 
    region_name,
    customer_count,
    total_sales,
    total_supplier_cost,
    supplier_orders
FROM 
    SalesSummary
WHERE 
    total_sales > (SELECT AVG(total_sales) FROM RegionSales)
    AND customer_count > (
        SELECT AVG(customer_count) FROM RegionSales WHERE region_name IS NOT NULL
    )
ORDER BY 
    total_sales DESC, customer_count DESC;
