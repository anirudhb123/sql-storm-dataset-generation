WITH RECURSIVE RegionSales AS (
    SELECT 
        r_name AS region_name,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM 
        region
    LEFT JOIN 
        nation ON r_regionkey = n_regionkey
    LEFT JOIN 
        supplier ON n_nationkey = s_nationkey
    LEFT JOIN 
        partsupp ON s_suppkey = ps_suppkey
    LEFT JOIN 
        part ON ps_partkey = p_partkey
    LEFT JOIN 
        lineitem ON p_partkey = l_partkey
    LEFT JOIN 
        orders ON l_orderkey = o_orderkey
    WHERE 
        o_orderdate >= '2022-01-01' AND o_orderdate < '2023-01-01'
    GROUP BY 
        r_name
    UNION ALL
    SELECT 
        region_name,
        CASE 
            WHEN total_sales IS NULL THEN 0 
            ELSE total_sales * 1.05 
        END AS total_sales
    FROM 
        RegionSales
)
SELECT 
    r_name AS region,
    COALESCE(SUM(total_sales), 0) AS total_sales,
    COUNT(DISTINCT s_suppkey) AS supplier_count,
    AVG(s_acctbal) AS average_supplier_balance,
    (SELECT COUNT(DISTINCT c_custkey) 
     FROM customer 
     WHERE c_nationkey IN (SELECT n_nationkey FROM nation WHERE n_regionkey = r.regionkey)) AS customer_count
FROM 
    region r
LEFT JOIN 
    RegionSales rs ON r.r_name = rs.region_name
LEFT JOIN 
    supplier s ON s.s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_regionkey = r.r_regionkey)
GROUP BY 
    r.r_regionkey, r.r_name
ORDER BY 
    total_sales DESC
LIMIT 10;
