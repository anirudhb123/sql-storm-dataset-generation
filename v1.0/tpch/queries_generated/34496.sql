WITH RECURSIVE RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_name
    
    UNION ALL
    
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) * 0.1 AS total_sales,
        0 AS total_orders
    FROM region r
    WHERE r.r_name NOT IN (SELECT region_name FROM RegionalSales)
)
SELECT 
    region_name,
    total_sales,
    total_orders,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM RegionalSales
WHERE total_sales > (SELECT AVG(total_sales) FROM RegionalSales WHERE total_orders > 0)
ORDER BY total_sales DESC
LIMIT 10;

WITH RecentOrders AS (
    SELECT 
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    ro.c_name,
    ro.o_orderkey,
    ro.o_orderdate,
    ro.order_total,
    CASE 
        WHEN ro.order_total IS NULL THEN 'No Sales' 
        ELSE 'Sale Made' 
    END AS order_status
FROM RecentOrders ro
LEFT JOIN customer c ON ro.c_name = c.c_name
WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
ORDER BY ro.order_total DESC, ro.o_orderdate DESC;
