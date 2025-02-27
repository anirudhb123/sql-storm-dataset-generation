WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 500
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey 
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 5000
),
PartSummary AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity * l.l_extendedprice) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY p.p_partkey, p.p_name
),
PartRanking AS (
    SELECT ps.p_partkey, ps.p_name,
           DENSE_RANK() OVER (ORDER BY ps.total_revenue DESC) AS part_rank
    FROM PartSummary ps
)
SELECT 
    r.r_name AS region, 
    n.n_name AS nation, 
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(COALESCE(ps.ps_supplycost, 0)) AS total_supply_cost,
    MAX(pr.part_rank) AS highest_part_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
LEFT JOIN PartRanking pr ON ps.ps_partkey = pr.p_partkey
WHERE c.c_acctbal IS NOT NULL
  AND (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY region, nation;