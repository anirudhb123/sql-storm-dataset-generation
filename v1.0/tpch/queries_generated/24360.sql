WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size IS NOT NULL AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL)
),
SupplierSales AS (
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
MaxSales AS (
    SELECT 
        MAX(total_sales) AS max_total_sales 
    FROM 
        SupplierSales
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    CASE 
        WHEN s.sales IS NULL THEN 'No Sales Data'
        ELSE CONCAT('Total Sales: ', CAST(s.sales AS VARCHAR))
    END AS sales_info,
    r.r_name AS region_name
FROM 
    RankedParts rp
LEFT JOIN 
    (SELECT 
         s.s_suppkey, SUM(total_sales) AS sales 
     FROM 
         SupplierSales s
     JOIN 
         nation n ON s.s_suppkey IN (SELECT s_nationkey FROM supplier WHERE s_suppkey = s.s_suppkey)
     WHERE 
         s.total_sales > (SELECT * FROM MaxSales) 
     GROUP BY 
         s.s_suppkey) s ON rp.p_partkey = s.s_suppkey
LEFT JOIN 
    (SELECT 
        DISTINCT n.n_nationkey, n.n_name 
     FROM 
        nation n
     WHERE 
        n.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name NOT IN ('Africa', 'Asia'))) r ON s.s_suppkey = r.n_nationkey
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.p_retailprice DESC NULLS LAST;
