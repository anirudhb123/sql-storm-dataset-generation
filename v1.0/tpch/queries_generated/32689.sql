WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 5
),
AggregatedOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartAvailability AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerSpending AS (
    SELECT c.c_custkey, c.c_name, a.total_spent, 
           RANK() OVER (PARTITION BY a.order_count ORDER BY a.total_spent DESC) AS rank_order
    FROM AggregatedOrders a
    JOIN customer c ON a.c_custkey = c.c_custkey
)
SELECT DISTINCT 
    c.c_name AS customer_name, 
    r.r_name AS region_name,
    ps.total_avail AS available_parts,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    CTE.nation_count
FROM customer c
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN lineitem l ON l.l_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '2023-01-01'
)
LEFT JOIN PartAvailability ps ON l.l_partkey = ps.p_partkey
CROSS JOIN (
    SELECT COUNT(DISTINCT n_nationkey) AS nation_count 
    FROM nation
) AS CTE
WHERE c.c_acctbal IS NOT NULL 
      AND r.r_name IS NOT NULL
      AND (c.c_mktsegment = 'BUILDING' OR c.c_mktsegment IS NULL)
GROUP BY c.c_name, r.r_name, ps.total_avail, CTE.nation_count
HAVING COALESCE(SUM(l.l_discount), 0) > 0.1
ORDER BY total_revenue DESC;
