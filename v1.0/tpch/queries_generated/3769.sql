WITH NationalSales AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
RankedSales AS (
    SELECT 
        n.nationkey, 
        n.n_name, 
        ns.total_sales,
        RANK() OVER (ORDER BY ns.total_sales DESC) AS sales_rank
    FROM 
        nation n
    LEFT JOIN 
        NationalSales ns ON n.n_nationkey = ns.n_nationkey
)
SELECT 
    r.r_name AS region, 
    rs.n_name AS nation,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rs.sales_rank, 'N/A') AS sales_rank
FROM 
    region r
LEFT JOIN 
    (SELECT DISTINCT n.n_regionkey, n.n_nationkey, n.n_name FROM nation n) AS na
    ON r.r_regionkey = na.n_regionkey
LEFT JOIN 
    RankedSales rs ON na.n_nationkey = rs.nationkey
WHERE 
    r.r_name LIKE 'A%' OR rs.sales_rank <= 5
ORDER BY 
    r.r_name, rs.sales_rank;
