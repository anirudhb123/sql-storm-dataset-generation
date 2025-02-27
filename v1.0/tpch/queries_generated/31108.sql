WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey + 1
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
EnhancedSales AS (
    SELECT 
        os.o_orderkey,
        os.item_count,
        os.total_sales,
        CASE 
            WHEN os.total_sales > 10000 THEN 'High'
            WHEN os.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low' 
        END AS sales_category
    FROM OrderSummary os
),
TopSales AS (
    SELECT DISTINCT 
        es.sales_category,
        es.item_count,
        DENSE_RANK() OVER (PARTITION BY es.sales_category ORDER BY es.total_sales DESC) AS rnk
    FROM EnhancedSales es
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    ss.total_cost AS supplier_total_cost,
    es.item_count AS order_item_count,
    es.total_sales AS order_total_sales,
    th.sales_category
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN EnhancedSales es ON ss.s_total_cost > 0
FULL OUTER JOIN TopSales th ON th.item_count = es.item_count
WHERE ss.total_cost IS NOT NULL OR th.sales_category IS NOT NULL
ORDER BY r.r_name, n.n_name, s.s_name;
