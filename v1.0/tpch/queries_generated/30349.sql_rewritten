WITH RECURSIVE RegionalSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) as sales_rank
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
TopRegions AS (
    SELECT 
        r.r_name,
        rs.total_sales
    FROM 
        region r
    LEFT JOIN 
        RegionalSales rs ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = rs.n_nationkey)
    WHERE 
        rs.sales_rank <= 5
)
SELECT 
    r.r_name,
    COALESCE(SUM(tr.total_sales), 0) AS total_sales
FROM 
    region r
LEFT JOIN 
    TopRegions tr ON r.r_name = tr.r_name
GROUP BY 
    r.r_name
ORDER BY 
    total_sales DESC;