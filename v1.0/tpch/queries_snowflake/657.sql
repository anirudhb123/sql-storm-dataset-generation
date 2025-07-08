
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
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
        o.o_orderstatus = 'F'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionNationalSales AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        SUM(ss.total_sales) AS region_sales
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        SupplierSales ss ON n.n_nationkey = (
            SELECT DISTINCT s.s_nationkey 
            FROM supplier s 
            WHERE s.s_suppkey = ss.s_suppkey)
    GROUP BY 
        n.n_nationkey, r.r_regionkey
)
SELECT 
    r.r_name,
    n.n_name,
    COALESCE(SUM(rs.region_sales), 0) AS total_region_sales,
    COUNT(DISTINCT n.n_nationkey) AS total_nations
FROM 
    region r
LEFT JOIN 
    RegionNationalSales rs ON r.r_regionkey = rs.r_regionkey
JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COALESCE(SUM(rs.region_sales), 0) > (SELECT AVG(total_sales) FROM SupplierSales)
ORDER BY 
    total_region_sales DESC, r.r_name ASC
LIMIT 10;
