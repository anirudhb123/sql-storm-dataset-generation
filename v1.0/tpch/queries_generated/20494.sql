WITH RECURSIVE country_sales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY 
        n.n_name, n.n_nationkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total_sales) FROM (SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_sales
                            FROM lineitem 
                            WHERE l_shipdate IS NOT NULL GROUP BY l_orderkey) AS avg_sales)
    UNION ALL
    SELECT 
        cs.nation_name,
        0 AS total_sales,
        cs.sales_rank
    FROM 
        country_sales cs
    WHERE 
        cs.sales_rank IS NULL
)
SELECT 
    r.r_name AS region_name,
    MAX(total_sales) AS max_sales,
    MIN(total_sales) AS min_sales,
    COUNT(DISTINCT nation_name) AS nation_count,
    CASE 
        WHEN MAX(total_sales) IS NULL THEN 'No Sales'
        ELSE 'Sales Found'
    END AS sales_status
FROM 
    country_sales
JOIN 
    nation n ON nation_name = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name
OFFSET 1 ROW FETCH NEXT 1 ROWS ONLY;
