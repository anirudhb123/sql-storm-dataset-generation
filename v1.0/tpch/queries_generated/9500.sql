WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        supplier s ON s.s_suppkey = l.l_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        p.p_partkey, p.p_name, n.n_nationkey
),
TopSales AS (
    SELECT 
        n.n_name,
        rs.p_name,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        nation n ON rs.sales_rank <= 5 AND n.n_nationkey = rs.n_nationkey
)
SELECT 
    n.r_name AS region_name,
    ts.n_name AS nation_name,
    ts.p_name AS product_name,
    ts.total_sales AS sales_amount
FROM 
    TopSales ts
JOIN 
    nation n ON ts.n_name = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ts.total_sales > 100000
ORDER BY 
    n.r_name, ts.total_sales DESC;
