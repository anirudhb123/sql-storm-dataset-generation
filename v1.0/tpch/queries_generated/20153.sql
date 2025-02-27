WITH RECURSIVE part_costs AS (
    SELECT 
        p_partkey,
        p_name,
        p_brand,
        p_container,
        p_mfgr,
        p_retailprice,
        ps_supplycost,
        COALESCE(SUM(l_extendedprice * (1 - l_discount)), 0) AS total_sales
    FROM 
        part
    JOIN 
        partsupp ON p_partkey = ps_partkey
    LEFT JOIN 
        lineitem ON l_partkey = p_partkey
    GROUP BY 
        p_partkey, ps_supplycost, p_name, p_brand, p_container, p_mfgr
    HAVING 
        SUM(l_extendedprice * (1 - l_discount)) > 1000
),
sales_per_country AS (
    SELECT
        n.n_name AS nation_name,
        SUM(pc.total_sales) AS sales_sum
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part_costs pc ON ps.ps_partkey = pc.p_partkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COALESCE(spc.sales_sum, 0) AS total_sales,
    CASE 
        WHEN COALESCE(spc.sales_sum, 0) IS NULL THEN 'No Sales'
        WHEN COALESCE(spc.sales_sum, 0) < 5000 THEN 'Low Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    sales_per_country spc ON n.n_nationkey = spc.nation_name
ORDER BY 
    region_name, total_sales DESC;
