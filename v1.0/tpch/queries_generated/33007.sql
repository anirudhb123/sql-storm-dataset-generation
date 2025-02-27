WITH RECURSIVE TotalSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
    UNION ALL
    SELECT 
        c.c_custkey,
        c.c_name,
        ts.total_sales + IFNULL(SUM(oi.l_extendedprice * (1 - oi.l_discount)), 0)
    FROM 
        TotalSales ts
    JOIN 
        lineitem oi ON ts.c_custkey = oi.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, ts.total_sales
),
RankedSales AS (
    SELECT 
        ts.c_custkey,
        ts.c_name,
        ts.total_sales,
        RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM 
        TotalSales ts
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ns.c_custkey) AS number_of_customers,
    AVG(ns.total_sales) AS avg_sales,
    MAX(ns.total_sales) AS max_sales
FROM 
    RankedSales ns
LEFT JOIN 
    nation n ON ns.c_custkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ns.sales_rank <= 10
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
