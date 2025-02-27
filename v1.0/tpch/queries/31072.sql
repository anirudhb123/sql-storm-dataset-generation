WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, SUM(p.p_retailprice) AS total_retail_price
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING SUM(p.p_retailprice) > 10000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_price
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
),
RankedOrders AS (
    SELECT co.c_custkey, co.order_count, co.total_price,
           RANK() OVER (PARTITION BY co.order_count ORDER BY co.total_price DESC) AS rank
    FROM CustomerOrders co
)
SELECT r.r_name, sh.s_name, ro.order_count, ro.total_price 
FROM TopRegions r
JOIN SupplierHierarchy sh ON r.r_regionkey = sh.s_nationkey
JOIN RankedOrders ro ON ro.total_price > 5000
WHERE sh.s_acctbal IS NOT NULL
AND r.total_retail_price BETWEEN 10000 AND 50000
ORDER BY r.r_name, sh.s_name, ro.total_price DESC;
