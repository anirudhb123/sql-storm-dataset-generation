WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, 1 AS depth
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE sh.depth < 5
), RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 20 
), ExpensiveOrders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
)
SELECT 
    rh.s_name AS supplier_name,
    p.p_name AS part_name,
    eo.o_totalprice AS expensive_order_total_price,
    (SELECT COUNT(*) FROM lineitem WHERE l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')) AS delivered_items,
    CASE 
        WHEN rh.depth IS NULL THEN 'No hierarchy'
        ELSE 'Hierarchy level: ' || CAST(rh.depth AS varchar)
    END AS hierarchy_info
FROM SupplierHierarchy rh
LEFT JOIN RankedParts p ON rh.s_suppkey = p.p_partkey
FULL OUTER JOIN ExpensiveOrders eo ON eo.o_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_orderkey IS NOT NULL)
WHERE rh.s_name LIKE '%Corp%'
ORDER BY rh.s_name, p.p_name, eo.o_totalprice DESC
LIMIT 100 OFFSET 10;
