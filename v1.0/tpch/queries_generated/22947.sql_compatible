
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE l.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY r.r_regionkey, r.r_name
),
TopRegions AS (
    SELECT region_name, total_sales, order_count 
    FROM RegionalSales 
    WHERE sales_rank <= 3
),
SupplierPartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    tr.region_name,
    COALESCE(spd.p_name, 'No Parts Available') AS part_name,
    tr.total_sales,
    ROUND(tr.total_sales / NULLIF(tr.order_count, 0), 2) AS avg_sale_per_order,
    CASE 
        WHEN spd.total_available_quantity IS NULL THEN 'Unavailable'
        WHEN spd.total_available_quantity < 100 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status,
    (SELECT COUNT(*) FROM supplier s WHERE s.s_nationkey IN 
         (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 
             (SELECT r.r_regionkey FROM region r WHERE r.r_name = tr.region_name))) 
    AS supplier_count
FROM TopRegions tr
LEFT JOIN SupplierPartDetails spd ON 1 = 1  
ORDER BY tr.total_sales DESC, tr.region_name;
