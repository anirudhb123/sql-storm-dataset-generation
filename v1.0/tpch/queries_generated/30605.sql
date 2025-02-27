WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
RegionStats AS (
    SELECT r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
),
PartSupplierStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_availqty,
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
),
FinalReport AS (
    SELECT ps.p_partkey, ps.p_name, ps.total_availqty,
           ps.avg_supplycost, rs.r_name, cs.c_custkey, cs.c_name,
           cs.order_count, cs.total_spent,
           ROW_NUMBER() OVER (PARTITION BY rs.r_name ORDER BY cs.total_spent DESC) AS rank
    FROM PartSupplierStats ps
    JOIN RegionStats rs ON ps.p_partkey % 10 = rs.nation_count % 10  -- Arbitrary join condition
    LEFT JOIN CustomerOrderStats cs ON cs.order_count > 5
)
SELECT f.r_name, f.p_name, f.total_availqty, f.avg_supplycost,
       f.c_name, f.order_count, f.total_spent
FROM FinalReport f
WHERE f.rank <= 3
ORDER BY f.r_name, f.total_spent DESC;
