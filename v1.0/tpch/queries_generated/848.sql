WITH RegionalSales AS (
    SELECT 
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM
        region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '2021-01-01'
        AND o.o_orderdate < DATE '2021-12-31'
    GROUP BY 
        r.r_name
), RankedSales AS (
    SELECT 
        region,
        total_sales,
        total_orders,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    rs.region,
    rs.total_sales,
    rs.total_orders,
    COALESCE(ROUND(rs.total_sales / NULLIF(rs.total_orders, 0), 2), 0) AS avg_order_value,
    CASE 
        WHEN rs.sales_rank <= 5 THEN 'Top 5 Region'
        WHEN rs.sales_rank > 5 AND rs.sales_rank <= 10 THEN 'Top 5 to 10 Region'
        ELSE 'Below Top 10 Region'
    END AS sales_category
FROM 
    RankedSales rs
ORDER BY 
    rs.total_sales DESC
LIMIT 10;

SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue
FROM 
    part p 
JOIN lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    l.l_shipdate >= DATE '2021-01-01' AND l.l_shipdate < DATE '2021-12-31'
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_quantity) > (SELECT AVG(total_quantity) 
                          FROM (SELECT SUM(l2.l_quantity) AS total_quantity
                                FROM lineitem l2 
                                GROUP BY l2.l_partkey) AS avg_quantity)
ORDER BY 
    total_revenue DESC
FETCH FIRST 10 ROWS ONLY;

