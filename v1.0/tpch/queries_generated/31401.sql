WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000.00 AND sh.level < 5
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size > 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    nh.n_name AS nation_name,
    ARRAY_AGG(DISTINCT lp.l_shipmode) AS available_ship_modes,
    AVG(lp.l_discount) AS avg_discount,
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM lineitem lp
JOIN orders o ON lp.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation nh ON c.c_nationkey = nh.n_nationkey
LEFT JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
WHERE lp.l_shipdate BETWEEN CURRENT_DATE - INTERVAL '30 days' AND CURRENT_DATE
AND (lp.l_returnflag IS NULL OR lp.l_returnflag != 'R')
AND EXISTS (
    SELECT 1
    FROM RankedParts rp
    WHERE rp.p_partkey = lp.l_partkey AND rp.price_rank <= 5
)
GROUP BY nh.n_name
HAVING SUM(lp.l_extendedprice * (1 - lp.l_discount)) > 50000
ORDER BY total_revenue DESC;
