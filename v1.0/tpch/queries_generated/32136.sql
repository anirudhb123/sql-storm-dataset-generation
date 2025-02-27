WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > 1000
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
NationRegions AS (
    SELECT n.n_nationkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
SupplierOrders AS (
    SELECT s.s_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey
)
SELECT
    p.p_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY order_total DESC) AS rank,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    CASE 
        WHEN SUM(l.l_discount) IS NULL THEN 'No discount applied'
        ELSE CONCAT('Total Discount: ', SUM(l.l_discount))
    END AS discount_info,
    n.r_name AS nation_region
FROM
    part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN OrderSummary o ON o.o_orderkey = l.l_orderkey
LEFT JOIN NationRegions n ON s.s_nationkey = n.n_nationkey
WHERE
    p.p_retailprice BETWEEN 10 AND 500
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 500)
GROUP BY
    p.p_partkey, s.s_suppkey, n.r_name
ORDER BY
    rank, total_quantity DESC
LIMIT 100;
