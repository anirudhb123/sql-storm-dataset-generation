WITH RECURSIVE RegionSales AS (
    SELECT 
        R.r_regionkey,
        R.r_name,
        SUM(L.l_extendedprice * (1 - L.l_discount)) AS total_sales,
        1 AS level
    FROM 
        region R
    JOIN 
        nation N ON R.r_regionkey = N.n_regionkey
    JOIN 
        supplier S ON N.n_nationkey = S.s_nationkey
    JOIN 
        partsupp PS ON S.s_suppkey = PS.ps_suppkey
    JOIN 
        part P ON PS.ps_partkey = P.p_partkey
    JOIN 
        lineitem L ON P.p_partkey = L.l_partkey
    GROUP BY 
        R.r_regionkey, R.r_name

    UNION ALL 

    SELECT 
        R.r_regionkey,
        R.r_name,
        SUM(L.l_extendedprice * (1 - L.l_discount)) AS total_sales,
        R.level + 1
    FROM 
        region R
    JOIN 
        nation N ON R.r_regionkey = N.n_regionkey
    JOIN 
        supplier S ON N.n_nationkey = S.s_nationkey
    JOIN 
        partsupp PS ON S.s_suppkey = PS.ps_suppkey
    JOIN 
        part P ON PS.ps_partkey = P.p_partkey
    JOIN 
        lineitem L ON P.p_partkey = L.l_partkey
    WHERE 
        L.l_shipdate >= DATE '2022-01-01'
        AND L.l_shipdate < DATE '2023-01-01'
    GROUP BY 
        R.r_regionkey, R.r_name
)

SELECT 
    R.r_name AS region_name,
    SUM(COALESCE(total_sales, 0)) AS aggregated_sales,
    COUNT(DISTINCT S.s_suppkey) AS supplier_count
FROM 
    region R
LEFT JOIN 
    RegionSales RS ON R.r_regionkey = RS.r_regionkey
LEFT JOIN 
    supplier S ON R.r_regionkey = S.s_nationkey
GROUP BY 
    R.r_name
HAVING 
    SUM(COALESCE(total_sales, 0)) > 10000
ORDER BY 
    aggregated_sales DESC;

SELECT 
    COUNT(*) AS total_orders,
    AVG(o_totalprice) AS avg_price
FROM 
    orders
WHERE 
    o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2023-01-01'
      AND o_orderstatus IN ('O', 'F');

SELECT 
    p_type,
    MIN(p_retailprice) AS min_price,
    MAX(p_retailprice) AS max_price
FROM 
    part
GROUP BY 
    p_type
HAVING 
    MAX(p_retailprice) - MIN(p_retailprice) > 50.00;
