WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, 0 AS level
    FROM customer
    WHERE c_acctbal > 1000

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') 
    WHERE c.c_acctbal < ch.c_acctbal
), HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 5000
), SupplierPartInfo AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available, MAX(p.p_retailprice) AS max_price
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_container IS NOT NULL
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), RegionOrders AS (
    SELECT r.r_regionkey, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY r.r_regionkey
)
SELECT 
    ch.c_name AS customer_name,
    COUNT(DISTINCT ho.o_orderkey) AS orders_count,
    AVG(ho.total_value) AS avg_order_value,
    COALESCE(ri.order_count, 0) AS region_order_count,
    sp.total_available,
    sp.max_price
FROM CustomerHierarchy ch
LEFT JOIN HighValueOrders ho ON ch.c_custkey = ho.o_custkey
LEFT JOIN RegionOrders ri ON ch.c_nationkey = ri.r_regionkey
JOIN SupplierPartInfo sp ON sp.ps_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = ho.o_custkey ORDER BY ps_availqty DESC LIMIT 1)
WHERE ch.level <= 3
GROUP BY ch.c_name, ri.order_count, sp.total_available, sp.max_price
ORDER BY avg_order_value DESC
LIMIT 10;
