WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 10000
    UNION ALL
    SELECT ch.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name IS NOT NULL AND n.n_nationkey = ch.c_nationkey)
    WHERE ch.level < 10
),
MaxOrderValue AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS max_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, COUNT(*) AS total_parts,
           CASE WHEN MIN(ps.ps_supplycost) IS NULL THEN 'Cheap'
                WHEN MIN(ps.ps_supplycost) < 50 THEN 'Affordable'
                ELSE 'Expensive' END AS pricing_category
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT 
    ch.c_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(COALESCE(m.max_value, 0)) AS total_order_value,
    s.total_parts,
    s.pricing_category,
    RANK() OVER (PARTITION BY s.pricing_category ORDER BY SUM(COALESCE(m.max_value, 0)) DESC) AS rank_within_category
FROM CustomerHierarchy ch
JOIN orders o ON o.o_custkey = ch.c_custkey
LEFT JOIN MaxOrderValue m ON o.o_orderkey = m.o_orderkey
JOIN SupplierInfo s ON s.total_parts > 5
WHERE ch.level = 1 AND o.o_orderstatus IN ('O', 'F')
GROUP BY ch.c_name, s.total_parts, s.pricing_category
HAVING COUNT(DISTINCT o.o_orderkey) > 2 AND SUM(COALESCE(m.max_value, 0)) > 1000
ORDER BY rank_within_category, total_orders DESC, total_order_value DESC;
