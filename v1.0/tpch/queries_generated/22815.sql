WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, h.level + 1
    FROM supplier s
    JOIN SupplierHierarchy h ON s.s_nationkey = h.s_nationkey
    WHERE s.suppkey <> h.s_suppkey AND h.level < 10
),
FilteredParts AS (
    SELECT p_partkey, p_name, p_retailprice, COUNT(*) OVER (PARTITION BY p_type) AS type_count
    FROM part
    WHERE p_size IS NOT NULL AND p_retailprice BETWEEN 20 AND 100
),
OrderDetails AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS item_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
ComplexOrders AS (
    SELECT od.o_orderkey,
           od.item_count,
           od.total_price,
           COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END), 0) AS return_count
    FROM OrderDetails od
    LEFT JOIN lineitem l ON od.o_orderkey = l.l_orderkey
    GROUP BY od.o_orderkey, od.item_count, od.total_price
)
SELECT s.s_name,
       p.p_name,
       CASE 
           WHEN c.item_count > 5 THEN 'High Volume'
           WHEN c.item_count BETWEEN 2 AND 5 THEN 'Medium Volume'
           ELSE 'Low Volume'
       END AS volume_category,
       p.type_count,
       c.total_price,
       COALESCE(SUM(CASE WHEN r.r_name IS NOT NULL THEN 1 ELSE 0 END), 0) AS region_count
FROM SupplierHierarchy s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN FilteredParts p ON ps.ps_partkey = p.p_partkey
JOIN complexorders c ON c.o_orderkey = ps.ps_partkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice IS NOT NULL
  AND p.p_comment LIKE '%quality%'
GROUP BY s.s_name, p.p_name, volume_category, p.type_count, c.total_price
HAVING SUM(c.return_count) < 3
ORDER BY total_price DESC, region_count ASC;
