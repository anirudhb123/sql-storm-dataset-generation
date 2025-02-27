WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 0 AS level
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL

    UNION ALL

    SELECT ch.c_custkey, ch.c_name, ch.c_nationkey, ch.level + 1
    FROM CustomerHierarchy ch
    JOIN orders o ON ch.c_custkey = o.o_custkey 
    WHERE o.o_orderstatus = 'O'
), 

SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) as total_available, 
           AVG(s.s_acctbal) as avg_account_balance, 
           COUNT(DISTINCT ps.ps_partkey) as part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), 

OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(DISTINCT l.l_partkey) as total_parts
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
), 

RegionDetails AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)

SELECT ch.c_name AS customer_name, rh.r_name AS region_name, 
       ss.total_available, ss.avg_account_balance, 
       os.total_price, os.total_parts
FROM CustomerHierarchy ch
LEFT JOIN nation n ON ch.c_nationkey = n.n_nationkey
LEFT JOIN RegionDetails rh ON n.n_regionkey = rh.r_regionkey
JOIN SupplierStats ss ON ss.total_available > (SELECT AVG(total_available) FROM SupplierStats)
JOIN OrderSummary os ON os.total_price > (SELECT AVG(total_price) FROM OrderSummary)
WHERE ch.level < 5
ORDER BY customer_name, region_name, total_parts DESC;
