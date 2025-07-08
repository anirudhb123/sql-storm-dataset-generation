WITH RECURSIVE RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER(PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        r.r_name
), 
TopRegions AS (
    SELECT 
        region_name,
        total_sales,
        sales_rank
    FROM 
        RegionalSales
    WHERE 
        sales_rank <= 5
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey
)
SELECT 
    tr.region_name,
    tr.total_sales,
    coc.order_count,
    CASE 
        WHEN coc.order_count IS NULL THEN 'No Orders'
        ELSE 'Orders Placed'
    END AS order_status
FROM 
    TopRegions tr
LEFT JOIN 
    CustomerOrderCounts coc ON coc.order_count > 0 
WHERE 
    NOT EXISTS (
        SELECT 1
        FROM lineitem l2
        WHERE l2.l_shipdate < DATE '1997-01-01' 
          AND l2.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = coc.c_custkey)
    )
ORDER BY 
    tr.total_sales DESC, tr.region_name;