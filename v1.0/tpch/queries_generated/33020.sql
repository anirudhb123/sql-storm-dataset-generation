WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 
           1 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 
           sh.hierarchy_level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, SUM(ps.ps_availqty) AS total_avail
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
    HAVING SUM(ps.ps_availqty) > 100
),
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
CustomerRegion AS (
    SELECT c.c_custkey, c.c_name, n.n_name AS region
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE n.n_name IS NOT NULL
)
SELECT 
    cr.region,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(co.total_value) AS total_order_value,
    STRING_AGG(DISTINCT tp.p_name, ', ') AS popular_parts
FROM HighValueOrders co
JOIN CustomerRegion cr ON cr.c_custkey = o.o_custkey
LEFT JOIN TopParts tp ON tp.total_avail > (SELECT AVG(total_avail) FROM TopParts)
WHERE cr.region LIKE '%East%'
GROUP BY cr.region
ORDER BY total_order_value DESC
LIMIT 10;
