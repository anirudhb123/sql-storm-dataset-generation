WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        l.l_shipdate >= DATE '2022-01-01' AND l.l_shipdate < DATE '2023-01-01'
    GROUP BY 
        r.r_regionkey, r.r_name
),
TopRegions AS (
    SELECT 
        region_name
    FROM 
        RegionalSales
    WHERE 
        sales_rank <= 3
)
SELECT 
    c.c_name AS customer_name,
    o.o_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
    COALESCE(s.s_name, 'UNKNOWN SUPPLIER') AS supplier_name,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Completed'
        WHEN o.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Unknown Order Status' 
    END AS order_status,
    STRING_AGG(DISTINCT p.p_name, ', ') AS purchased_items
FROM 
    orders o
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    EXISTS (
        SELECT 1 
        FROM TopRegions tr 
        WHERE tr.region_name = (
            SELECT r.r_name
            FROM region r
            JOIN nation n ON r.r_regionkey = n.n_regionkey
            JOIN supplier sup ON n.n_nationkey = sup.s_nationkey
            WHERE sup.s_suppkey = s.s_suppkey
        )
    )
GROUP BY 
    c.c_name, o.o_orderkey, o.o_orderstatus, s.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    order_total DESC NULLS LAST;
