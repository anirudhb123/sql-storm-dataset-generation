WITH RECURSIVE MonthlySales AS (
    SELECT 
        EXTRACT(YEAR FROM o_orderdate) AS sales_year,
        EXTRACT(MONTH FROM o_orderdate) AS sales_month,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        sales_year, sales_month
    UNION ALL
    SELECT 
        sales_year,
        sales_month + 1 AS sales_month,
        SUM(l_extendedprice * (1 - l_discount))
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        EXTRACT(MONTH FROM o_orderdate) < 12
    GROUP BY 
        sales_year, sales_month + 1
),
SalesRanked AS (
    SELECT 
        sales_year,
        sales_month,
        total_sales,
        RANK() OVER (PARTITION BY sales_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        MonthlySales
),
TopSales AS (
    SELECT 
        sr.sales_year,
        sr.sales_month,
        sr.total_sales
    FROM 
        SalesRanked sr
    WHERE 
        sr.sales_rank <= 5
)
SELECT 
    p.p_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    COALESCE(rs.total_sales, 0) AS reported_sales
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    nation n ON ps.ps_suppkey = n.n_nationkey
LEFT JOIN 
    (
        SELECT 
            sales_year,
            sales_month,
            SUM(total_sales) AS total_sales
        FROM 
            TopSales
        GROUP BY 
            sales_year, sales_month
    ) rs ON rs.sales_month = EXTRACT(MONTH FROM CURRENT_DATE) AND rs.sales_year = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY 
    p.p_name, rs.total_sales
HAVING 
    total_supply_cost > (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    reported_sales DESC, total_supply_cost ASC;
