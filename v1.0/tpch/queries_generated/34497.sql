WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE s.s_acctbal < sh.s_acctbal
),
SalesData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
TopSales AS (
    SELECT sd.c_custkey, sd.c_name, sd.total_sales
    FROM SalesData sd
    WHERE sd.rank <= 5
),
SupplierSales AS (
    SELECT 
        sh.s_name,
        COUNT(l.l_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_sales
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier sh ON ps.ps_suppkey = sh.s_suppkey
    GROUP BY sh.s_name
)
SELECT 
    ns.n_name,
    COUNT(DISTINCT ss.s_name) AS supplier_count,
    SUM(ts.total_sales) AS combined_sales,
    AVG(ss.total_orders) AS avg_orders_per_supplier
FROM nation ns
LEFT JOIN SupplierHierarchy sh ON ns.n_nationkey = sh.s_nationkey
LEFT JOIN TopSales ts ON ns.n_nationkey = ts.c_nationkey
LEFT JOIN SupplierSales ss ON sh.s_name = ss.s_name
WHERE ns.n_name LIKE '%land%' OR ns.n_comment IS NULL
GROUP BY ns.n_name
ORDER BY combined_sales DESC;
