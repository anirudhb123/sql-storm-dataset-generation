WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_size,
        CASE 
            WHEN p.p_retailprice > 1000 THEN 'Luxury' 
            WHEN p.p_retailprice BETWEEN 500 AND 1000 THEN 'Premium' 
            ELSE 'Standard' 
        END AS p_category
    FROM part p
    WHERE p.p_size IS NOT NULL
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        CASE 
            WHEN o.o_orderstatus = 'O' THEN 'Open' 
            WHEN o.o_orderstatus = 'F' THEN 'Finished' 
            ELSE 'Unknown' 
        END AS order_status_desc,
        COUNT(DISTINCT l.l_orderkey) OVER (PARTITION BY o.o_orderkey) AS line_count
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
),
TotalSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN HighValueParts p ON l.l_partkey = p.p_partkey
    GROUP BY p.p_partkey
)
SELECT 
    r.r_name AS region_name,
    np.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    SUM(ts.total_sales) AS total_sales_amount,
    AVG(s.s_acctbal) AS average_supplier_balance,
    MIN(COALESCE(ts.total_sales, 0)) AS min_sales_per_part,
    MAX(COALESCE(ts.total_sales, 0)) AS max_sales_per_part,
    STRING_AGG(DISTINCT p.p_category, ', ') AS part_categories
FROM region r
JOIN nation np ON r.r_regionkey = np.n_regionkey
LEFT JOIN supplier s ON s.s_nationkey = np.n_nationkey
LEFT JOIN FilteredOrders o ON o.o_custkey IN (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_nationkey = np.n_nationkey AND c.c_acctbal > 0
)
LEFT JOIN TotalSales ts ON ts.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_supplycost < 200
)
GROUP BY r.r_name, np.n_name
HAVING SUM(ts.total_sales) > (
    SELECT AVG(total_sales_amount) FROM (
        SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales_amount
        FROM lineitem l
        GROUP BY l.l_partkey
    ) AS sales_subquery
)
ORDER BY region_name, nation_name;
