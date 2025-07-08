
WITH RECURSIVE RegionSales (r_regionkey, r_name, total_sales, level) AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        1 AS level
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_regionkey, r.r_name

    UNION ALL

    SELECT 
        rs.r_regionkey,
        rs.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        rs.level + 1
    FROM 
        RegionSales rs
    JOIN 
        nation n ON rs.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        rs.r_regionkey, rs.r_name, rs.level
),
OrderedSales AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name,
    COALESCE(ordered.total_sales, 0) AS total_sales,
    CASE 
        WHEN ordered.total_sales IS NOT NULL THEN 'Sales Available' 
        ELSE 'No Sales' 
    END AS sales_status
FROM 
    region r
LEFT JOIN 
    (SELECT * FROM OrderedSales WHERE rn <= 5) ordered ON r.r_regionkey = ordered.r_regionkey
WHERE 
    EXISTS (SELECT 1 FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)) 
ORDER BY 
    r.r_name;
