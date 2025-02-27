WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartStats AS (
    SELECT p.p_partkey,
           p.p_name,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
OrderStats AS (
    SELECT o.o_custkey,
           COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_revenue
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
    GROUP BY o.o_custkey
),
CustomerRanking AS (
    SELECT c.c_custkey,
           RANK() OVER (ORDER BY os.total_revenue DESC) AS customer_rank
    FROM customer c
    JOIN OrderStats os ON c.c_custkey = os.o_custkey
)

SELECT r.r_name AS region_name,
       n.n_name AS nation_name,
       sh.s_name AS supplier_name,
       ps.total_available,
       ps.avg_supplycost,
       cr.customer_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN PartStats ps ON sh.s_suppkey = ps.p_partkey
LEFT JOIN CustomerRanking cr ON cr.c_custkey = sh.s_nationkey
WHERE ps.total_available IS NOT NULL
AND PS.avg_supplycost < (SELECT AVG(avg_supplycost) FROM PartStats)
ORDER BY r.r_name, n.n_name, cr.customer_rank;
