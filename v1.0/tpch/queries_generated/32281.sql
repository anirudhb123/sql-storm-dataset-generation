WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, CAST(s_name AS VARCHAR(255)) AS full_path
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, CONCAT(sh.full_path, ' -> ', s.s_name)
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000 AND sh.s_suppkey <> s.s_suppkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
),
CustomerOrder AS (
    SELECT c.c_custkey, c.c_name, os.o_orderkey, os.net_revenue
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_orderkey
    WHERE c.c_acctbal > 5000
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice BETWEEN 100 AND 500
    GROUP BY p.p_partkey, p.p_name
)
SELECT DISTINCT ch.c_custkey, ch.c_name, ph.p_partkey, ph.p_name, sh.full_path AS supplier_path,
       COALESCE(os.net_revenue, 0) AS order_revenue, COALESCE(ps.total_supply_cost, 0) AS supply_cost
FROM CustomerOrder ch
LEFT JOIN FilteredParts ps ON ps.total_supply_cost > 0
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = ch.c_custkey
LEFT JOIN OrderSummary os ON os.o_orderkey = ch.o_orderkey
WHERE (os.net_revenue > 1000 OR os.net_revenue IS NULL)
  AND (ph.total_supply_cost IS NOT NULL OR ph.total_supply_cost = 0)
ORDER BY ch.c_custkey, ph.p_name;
