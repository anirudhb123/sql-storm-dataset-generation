WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00 -- Starting point for recursion

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),

PartStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),

OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),

NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE n.n_name IS NOT NULL
)

SELECT s.s_name AS Supplier_Name,
       p.p_name AS Part_Name,
       ps.total_supplycost,
       os.net_revenue,
       nr.r_name AS Region_Name,
       ROW_NUMBER() OVER (PARTITION BY nr.r_name ORDER BY os.net_revenue DESC) AS revenue_rank,
       COUNT(DISTINCT sh.s_suppkey) AS related_suppliers
FROM PartStats ps
JOIN OrderStats os ON ps.p_partkey = os.o_orderkey
JOIN SupplierHierarchy sh ON sh.s_nationkey = (
    SELECT n.n_nationkey
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = os.o_orderkey)
)
JOIN NationRegion nr ON nr.n_nationkey = sh.s_nationkey
LEFT JOIN supplier s ON s.s_suppkey = sh.s_suppkey
WHERE ps.total_supplycost IS NOT NULL
  AND os.net_revenue > 0
ORDER BY nr.r_name, revenue_rank;
