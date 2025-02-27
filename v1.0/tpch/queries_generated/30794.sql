WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 5000

    UNION ALL

    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal < 4000
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 100.00 OR ps.ps_availqty > 200
    GROUP BY p.p_partkey, p.p_name
)
SELECT cr.c_name, hs.s_name, h.total_cost,
       ROW_NUMBER() OVER (PARTITION BY cr.c_name ORDER BY h.total_cost DESC) AS rank
FROM CustomerOrderSummary cr
FULL OUTER JOIN SupplierHierarchy hs ON cr.c_custkey = hs.s_nationkey
JOIN HighValueParts h ON hs.s_suppkey = h.p_partkey
WHERE (cr.order_count > 5 OR h.total_cost IS NOT NULL)
  AND (hs.level < 3 OR hs.s_name LIKE '%Inc%')
ORDER BY cr.c_name, h.total_cost DESC;
