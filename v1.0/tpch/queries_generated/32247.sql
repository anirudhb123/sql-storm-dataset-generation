WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal BETWEEN 0.1 * sh.hierarchy_level * (SELECT AVG(s_acctbal) FROM supplier) AND 
                           0.2 * sh.hierarchy_level * (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
Ranking AS (
    SELECT c.c_custkey, c.c_name, co.order_count, co.total_spent,
           RANK() OVER (ORDER BY co.total_spent DESC) AS cust_rank,
           DENSE_RANK() OVER (PARTITION BY co.order_count ORDER BY co.total_spent DESC) AS order_rank
    FROM CustomerOrders co
    INNER JOIN customer c ON co.c_custkey = c.c_custkey
)
SELECT r.r_name, ps.p_name, ps.total_available, ps.avg_supply_cost,
       sh.hierarchy_level, rank.cust_rank, rank.order_rank
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN Ranking rank ON rank.cust_rank < 5
WHERE ps.total_available > 100 
  AND ps.avg_supply_cost IS NOT NULL
  AND r.r_name IS NOT NULL
ORDER BY rank.order_rank, ps.total_available DESC;
