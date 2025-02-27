WITH RECURSIVE NationalSales AS (
    SELECT 
        n.n_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        customer c ON c.c_custkey = o.o_custkey
    JOIN 
        orders o ON o.o_orderkey = l.l_orderkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
),
FilteredSales AS (
    SELECT n_name, total_sales
    FROM NationalSales
    WHERE sales_rank <= 3
)

SELECT 
    r.r_name AS region,
    COALESCE(fs.n_name, 'Unknown') AS nation,
    SUM(fs.total_sales) AS total_sales
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    FilteredSales fs ON n.n_name = fs.n_name
GROUP BY 
    r.r_name, fs.n_name
HAVING 
    SUM(fs.total_sales) IS NOT NULL OR SUM(fs.total_sales) IS NULL
ORDER BY 
    region, total_sales DESC
LIMIT 10
UNION ALL
SELECT 
    r.r_name AS region,
    'Total' AS nation,
    SUM(fs.total_sales) AS total_sales
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    FilteredSales fs ON n.n_name = fs.n_name
GROUP BY 
    r.r_name
ORDER BY 
    total_sales DESC;
