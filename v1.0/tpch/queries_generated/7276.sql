WITH RegionCustomerSales AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        c.c_name AS customer_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        r.r_name, n.n_name, c.c_name
),
TopRegions AS (
    SELECT 
        region_name,
        SUM(total_sales) AS region_total_sales
    FROM 
        RegionCustomerSales
    GROUP BY 
        region_name
    ORDER BY 
        region_total_sales DESC
    LIMIT 5
),
SupplierPartSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    r.region_name,
    r.nation_name,
    r.customer_name,
    s.ps_partkey,
    s.total_sales AS supplier_part_sales
FROM 
    RegionCustomerSales r
JOIN 
    TopRegions t ON r.region_name = t.region_name
JOIN 
    SupplierPartSales s ON s.total_sales > 50000
ORDER BY 
    r.region_name, r.nation_name, r.customer_name, s.total_sales DESC;
