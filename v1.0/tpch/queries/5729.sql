WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation,
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
        n.n_name
),
SalesRanked AS (
    SELECT 
        nation,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    sr.nation,
    sr.total_sales,
    sr.sales_rank,
    r.r_comment
FROM 
    SalesRanked sr
JOIN 
    region r ON (sr.nation = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = r.r_regionkey))
WHERE 
    sr.sales_rank <= 10
ORDER BY 
    sr.sales_rank;
