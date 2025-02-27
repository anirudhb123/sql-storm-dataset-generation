WITH RECURSIVE region_sales AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
        LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
        LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
        LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
        LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        r.r_regionkey, r.r_name

    UNION ALL

    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
        LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
        LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
        LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
        LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate <= DATE '1997-01-01'
    GROUP BY 
        r.r_regionkey, r.r_name
),
ranked_sales AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(rs.total_sales) AS total_annual_sales,
        RANK() OVER (ORDER BY SUM(rs.total_sales) DESC) AS sales_rank
    FROM 
        region_sales rs
        JOIN region r ON rs.r_regionkey = r.r_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name,
    COALESCE(r.total_annual_sales, 0) AS annual_sales,
    CASE 
        WHEN r.sales_rank IS NULL THEN 'Not Ranked'
        ELSE CAST(r.sales_rank AS VARCHAR)
    END AS sales_rank,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    ranked_sales r
    LEFT JOIN orders o ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = o.o_custkey)
    LEFT JOIN customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    r.r_name, r.total_annual_sales, r.sales_rank
ORDER BY 
    annual_sales DESC;