WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
SalesStats AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
),
TotalSales AS (
    SELECT 
        c.c_nationkey,
        SUM(s.total_sales) AS nation_sales,
        SUM(s.order_count) AS total_orders
    FROM SalesStats s
    JOIN customer c ON s.c_custkey = c.c_custkey
    GROUP BY c.c_nationkey
)
SELECT 
    n.n_name,
    ns.supplier_count,
    ns.total_available_qty,
    ts.nation_sales,
    ts.total_orders
FROM NationSummary ns
JOIN nation n ON ns.n_nationkey = n.n_nationkey
LEFT JOIN TotalSales ts ON n.n_nationkey = ts.c_nationkey
WHERE ns.supplier_count > 5
ORDER BY nation_sales DESC
LIMIT 10;
