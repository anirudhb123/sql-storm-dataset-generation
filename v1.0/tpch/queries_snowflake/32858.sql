WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
  
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000 AND sh.level < 5
),
OrdersWithDiscounts AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_discounted_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount > 0
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierStats AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    os.total_discounted_price,
    ss.total_available,
    ss.avg_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY os.total_discounted_price DESC) AS rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN OrdersWithDiscounts os ON s.s_suppkey = os.o_orderkey
LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.p_partkey
WHERE ss.avg_supply_cost IS NOT NULL
  AND (ss.total_available > 50 OR ss.total_available IS NULL)
  AND os.total_discounted_price > 10000
ORDER BY region_name, rank;
