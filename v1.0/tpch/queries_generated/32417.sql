WITH RECURSIVE regional_sales AS (
    SELECT 
        n.n_nationkey,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        n.n_nationkey, r.r_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
excluded_sales AS (
    SELECT 
        n.n_nationkey,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS excluded_total_sales
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate < '2022-01-01'
    GROUP BY 
        n.n_nationkey, r.r_name
)
SELECT 
    r.region_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(es.excluded_total_sales, 0) AS excluded_sales,
    (COALESCE(rs.total_sales, 0) - COALESCE(es.excluded_total_sales, 0)) AS net_sales
FROM 
    regional_sales rs
FULL OUTER JOIN 
    excluded_sales es ON rs.n_nationkey = es.n_nationkey
JOIN 
    region r ON rs.region_name = r.r_name OR es.region_name = r.r_name
WHERE 
    (rs.sales_rank = 1 OR es.n_nationkey IS NOT NULL)
ORDER BY 
    net_sales DESC, r.region_name ASC;
