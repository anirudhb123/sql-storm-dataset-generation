WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
AggregatedSales AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
),
Summary AS (
    SELECT 
        sr.r_name,
        COUNT(DISTINCT ns.n_nationkey) AS nation_count,
        SUM(as.total_spent) AS total_sales,
        SUM(as.order_count) AS total_orders,
        AVG(CASE WHEN as.avg_quantity IS NOT NULL THEN as.avg_quantity ELSE 0 END) AS avg_order_quantity
    FROM region sr
    LEFT JOIN nation ns ON sr.r_regionkey = ns.n_regionkey
    LEFT JOIN AggregatedSales as ON ns.n_nationkey = as.c_custkey
    GROUP BY sr.r_name
)

SELECT 
    r.r_name,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END), 0) AS total_returns,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    CONCAT(SUBSTRING(r.r_name, 1, 5), '... and regions') AS short_region_name,
    CASE 
        WHEN COUNT(DISTINCT sh.s_suppkey) > 5 THEN 'Many Suppliers' 
        ELSE 'Few Suppliers' 
    END AS supplier_category
FROM Summary s
JOIN region r ON s.r_name = r.r_name
LEFT JOIN lineitem l ON s.total_sales > 50000 AND l.l_discount < 0.1
LEFT JOIN SupplierHierarchy sh ON r.r_regionkey = sh.s_nationkey
GROUP BY r.r_name
HAVING SUM(COALESCE(l.l_extendedprice, 0)) > 100000
ORDER BY total_returns DESC, r.r_name ASC;
