
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        region r
        JOIN nation n ON r.r_regionkey = n.n_regionkey
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN part p ON ps.ps_partkey = p.p_partkey
        JOIN lineitem l ON l.l_partkey = p.p_partkey
        JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND 
        (l.l_discount < 0.05 OR l.l_tax > 0.07)
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        region_name,
        total_sales,
        total_orders,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
),
CombinedInfo AS (
    SELECT 
        tr.region_name,
        tr.total_sales,
        tr.total_orders,
        CASE 
            WHEN tr.total_sales IS NULL THEN 'No Sales'
            WHEN tr.total_orders = 0 THEN 'No Orders Placed'
            ELSE 'Active Sales'
        END AS sales_status,
        LISTAGG(p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS popular_parts
    FROM 
        TopRegions tr
        LEFT JOIN part p ON p.p_partkey IN (
            SELECT p2.p_partkey FROM part p2
            WHERE p2.p_retailprice > (
                SELECT AVG(p3.p_retailprice) FROM part p3
            )
        )
    GROUP BY 
        tr.region_name, tr.total_sales, tr.total_orders
)
SELECT 
    ci.region_name,
    ci.total_sales,
    ci.total_orders,
    ci.sales_status,
    COALESCE(ci.popular_parts, 'N/A') AS popular_parts
FROM 
    CombinedInfo ci
JOIN TopRegions tr ON ci.region_name = tr.region_name
WHERE 
    tr.sales_rank <= 5 
    OR ci.sales_status = 'No Sales'
ORDER BY 
    ci.total_sales DESC NULLS LAST;
