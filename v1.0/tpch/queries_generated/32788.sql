WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
sales_summary AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_nationkey
),
part_supplier_info AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
combined_sales AS (
    SELECT 
        nh.n_name, 
        ss.total_sales, 
        ss.order_count, 
        psi.total_available, 
        psi.avg_supply_cost
    FROM sales_summary ss
    JOIN nation_hierarchy nh ON ss.c_nationkey = nh.n_nationkey
    LEFT JOIN part_supplier_info psi ON psi.rank = 1
)
SELECT 
    cs.n_name, 
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cs.order_count, 0) AS order_count,
    COALESCE(cs.total_available, 0) AS total_available,
    COALESCE(cs.avg_supply_cost, 0) AS avg_supply_cost,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        WHEN cs.total_sales > 10000 THEN 'High Sales'
        ELSE 'Moderate Sales'
    END AS sales_category
FROM combined_sales cs
ORDER BY cs.n_name ASC
FETCH FIRST 100 ROWS ONLY;
