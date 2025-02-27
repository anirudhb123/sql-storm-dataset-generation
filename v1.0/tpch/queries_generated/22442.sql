WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),  
SalesData AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_shipdate < CURRENT_DATE - INTERVAL '2 days'
    GROUP BY 
        c.c_custkey
), 
RegionSales AS (
    SELECT 
        n.n_regionkey,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(sd.total_sales) AS region_sales
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        SalesData sd ON c.c_custkey = sd.c_custkey
    GROUP BY 
        n.n_regionkey
), 
SalesComparison AS (
    SELECT 
        rs.r_regionkey,
        rs.customer_count,
        rs.region_sales,
        (rs.region_sales / NULLIF(NULLIF(SUM(rs.region_sales) OVER (), 0), 0)) * 100) AS percentage_of_total_sales
    FROM 
        RegionSales rs
), 
TopSellingParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_part_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_part_sales DESC
    LIMIT 10
)
SELECT 
    rs.r_regionkey,
    COALESCE(SUM(ts.total_part_sales), 0) AS total_top_part_sales,
    COUNT(*) FILTER (WHERE rs.region_sales > 100000) AS high_value_regions,
    STRING_AGG(DISTINCT rs.r_regionkey::TEXT, ', ') AS region_keys
FROM 
    SalesComparison rs
LEFT JOIN 
    TopSellingParts ts ON ts.total_part_sales > 0
GROUP BY 
    rs.r_regionkey
HAVING 
    COUNT(DISTINCT ts.p_partkey) > 0
ORDER BY 
    total_top_part_sales DESC, rs.r_regionkey;
