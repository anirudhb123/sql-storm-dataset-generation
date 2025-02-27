WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= '2022-01-01' AND 
        o.o_orderdate < '2023-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionSales AS (
    SELECT 
        r.r_name,
        SUM(ss.total_sales) AS region_total_sales,
        AVG(ss.total_sales) AS region_avg_sales
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        SupplierSales ss ON o.o_orderkey IN (SELECT o2.o_orderkey FROM orders o2 WHERE o2.o_custkey = c.c_custkey)
    GROUP BY 
        r.r_name
),
RankedSales AS (
    SELECT 
        r.r_name,
        rs.region_total_sales,
        rs.region_avg_sales,
        RANK() OVER (ORDER BY rs.region_total_sales DESC) AS sales_rank
    FROM 
        RegionSales rs
    JOIN 
        region r ON rs.r_name = r.r_name
)

SELECT 
    r.r_name,
    COALESCE(rs.region_total_sales, 0) AS total_sales,
    COALESCE(rs.region_avg_sales, 0) AS avg_sales,
    rs.sales_rank
FROM 
    region r
LEFT JOIN 
    RankedSales rs ON r.r_name = rs.r_name
ORDER BY 
    rs.sales_rank, r.r_name;
