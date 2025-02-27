
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 100000
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal, sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_acctbal > 50000
),
AggregateSales AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        MIN(l.l_shipdate) AS first_ship_date,
        MAX(l.l_shipdate) AS last_ship_date,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY l.l_orderkey
),
NationSales AS (
    SELECT n.n_name, SUM(a.total_sales) AS nation_total_sales
    FROM nation n
    LEFT JOIN AggregateSales a ON EXISTS (
        SELECT 1
        FROM customer c
        JOIN orders o ON c.c_custkey = o.o_custkey
        WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l)
        AND c.c_nationkey = n.n_nationkey
    )
    GROUP BY n.n_name
)
SELECT 
    n.n_name,
    n.n_comment,
    COALESCE(ns.nation_total_sales, 0) AS nation_total_sales,
    COUNT(DISTINCT sh.s_suppkey) AS total_suppliers,
    ROUND(AVG(sh.s_acctbal), 2) AS avg_supplier_balance
FROM nation n
LEFT JOIN NationSales ns ON n.n_name = ns.n_name
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
GROUP BY n.n_name, n.n_comment, ns.nation_total_sales
HAVING COUNT(DISTINCT sh.s_suppkey) > 5
ORDER BY nation_total_sales DESC, avg_supplier_balance ASC
LIMIT 10;
