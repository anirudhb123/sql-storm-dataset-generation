WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, sh.s_name, sh.s_nationkey, sh.level + 1
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.level < 5
),
DiscountedOrders AS (
    SELECT o.o_orderkey, SUM(CASE 
           WHEN l.l_discount IS NOT NULL THEN l.l_extendedprice * (1 - l.l_discount)
           ELSE l.l_extendedprice
       END) AS total_discounted_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipmode IN ('AIR', 'GROUND')
    GROUP BY o.o_orderkey
),
MaxCustomerSpent AS (
    SELECT c.c_custkey, MAX(o.o_totalprice) AS max_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING COUNT(DISTINCT o.o_orderkey) > 5
),
RegionNation AS (
    SELECT r.r_name, n.n_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name, n.n_name
    HAVING COUNT(n.n_nationkey) > 0
)
SELECT 
    p.p_name,
    (CASE 
        WHEN SUM(l.l_quantity) IS NULL THEN 'No Sales' 
        ELSE CAST(SUM(l.l_quantity) AS VARCHAR)
     END) AS total_quantity,
    rh.r_name,
    s.s_name,
    COALESCE(MAX(cs.max_spent), 0) AS max_customer_spent,
    (SELECT COUNT(DISTINCT l.l_suppkey) 
     FROM lineitem l 
     WHERE l.l_returnflag = 'R') AS return_count
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN SupplierHierarchy sh ON l.l_suppkey = sh.s_suppkey
LEFT JOIN RegionNation rh ON sh.s_nationkey = rh.n.n_nationkey
LEFT JOIN MaxCustomerSpent cs ON cs.c_custkey = l.l_suppkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
GROUP BY p.p_partkey, rh.r_name, s.s_name
ORDER BY total_quantity DESC NULLS LAST
LIMIT 10
OFFSET 5;
