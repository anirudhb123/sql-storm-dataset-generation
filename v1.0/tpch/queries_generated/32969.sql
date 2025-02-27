WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
OrderTotal AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(DISTINCT n.n_nationkey) > 2
)
SELECT 
    s.s_name,
    COALESCE(SUM(ot.total_order_value), 0) AS total_value,
    tr.region_name,
    CASE 
        WHEN SUM(ot.total_order_value) IS NULL THEN 'No Orders'
        WHEN SUM(ot.total_order_value) < 10000 THEN 'Low Value'
        ELSE 'High Value' 
    END AS value_category,
    CONCAT(s.s_name, ' is from ', n.n_name) AS supplier_info
FROM SupplierHierarchy s
LEFT JOIN OrderTotal ot ON s.s_suppkey = ot.o_orderkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN TopRegions tr ON n.n_regionkey = tr.r_regionkey
GROUP BY s.s_name, tr.region_name
ORDER BY total_value DESC
LIMIT 10;
