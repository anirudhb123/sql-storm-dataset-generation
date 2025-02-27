WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
    WHERE 
        l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        n.n_name
),
TopRegions AS (
    SELECT
        nation,
        total_sales
    FROM 
        RegionalSales
    WHERE 
        sales_rank <= 5
),
SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice) AS total_order_value
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        s.s_suppkey
)
SELECT 
    tr.nation,
    tr.total_sales,
    so.order_count,
    so.total_order_value,
    COALESCE(so.total_order_value / NULLIF(so.order_count, 0), 0) AS avg_order_value,
    CASE 
        WHEN tr.total_sales > 1000000 THEN 'High Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    TopRegions tr
FULL OUTER JOIN 
    SupplierOrders so ON tr.nation = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = so.s_suppkey))
WHERE 
    tr.total_sales IS NOT NULL OR so.order_count IS NOT NULL
ORDER BY 
    tr.total_sales DESC NULLS LAST, so.order_count ASC NULLS FIRST;