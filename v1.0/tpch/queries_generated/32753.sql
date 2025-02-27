WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (sh.s_acctbal / 2)
),
TotalPrice AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
NationalAverage AS (
    SELECT n.n_name, AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
SupplierStats AS (
    SELECT
        sh.s_nationkey,
        COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
        SUM(sh.s_acctbal) AS total_acctbal,
        AVG(sh.s_acctbal) AS avg_acctbal
    FROM SupplierHierarchy sh
    GROUP BY sh.s_nationkey
)
SELECT 
    n.n_name,
    COALESCE(sa.supplier_count, 0) AS supplier_count,
    COALESCE(sa.total_acctbal, 0) AS total_supplier_acctbal,
    COALESCE(sa.avg_acctbal, 0) AS average_supplier_acctbal,
    COALESCE(tp.total_order_price, 0) AS total_order_price,
    ROUND(COALESCE(nt.avg_acctbal, 0), 2) AS national_avg_acctbal
FROM nation n
LEFT JOIN SupplierStats sa ON n.n_nationkey = sa.s_nationkey
LEFT JOIN TotalPrice tp ON tp.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o
    WHERE o.o_orderstatus = 'F' 
    AND o.o_orderpriority LIKE ' urgently%' 
)
LEFT JOIN NationalAverage nt ON nt.n_name = n.n_name
WHERE (n.n_name LIKE 'A%' OR n.n_name LIKE 'B%')
ORDER BY total_order_price DESC, supplier_count DESC;
