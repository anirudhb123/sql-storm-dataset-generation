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
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' 
        AND l.l_shipdate < DATE '2024-01-01' 
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionSales AS (
    SELECT 
        n.n_regionkey,
        SUM(ss.total_sales) AS region_sales
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_regionkey
)
SELECT 
    r.r_name,
    COALESCE(rs.region_sales, 0) AS sales_amount,
    CASE 
        WHEN rs.region_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status,
    SUM(p.p_retailprice) AS total_part_retail_price
FROM 
    region r
LEFT JOIN 
    RegionSales rs ON r.r_regionkey = rs.n_regionkey
JOIN 
    (SELECT 
         p_partkey, 
         SUM(ps.ps_availqty) AS total_available
     FROM 
         part p
     LEFT JOIN 
         partsupp ps ON p.p_partkey = ps.ps_partkey
     WHERE 
         ps.ps_availqty > 0
     GROUP BY 
         p.p_partkey) available_parts ON 1 = 1
GROUP BY 
    r.r_regionkey, 
    r.r_name, 
    rs.region_sales
ORDER BY 
    sales_amount DESC, 
    total_part_retail_price ASC
FETCH FIRST 10 ROWS ONLY;
