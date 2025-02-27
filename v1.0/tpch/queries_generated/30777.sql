WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level, CAST(s.s_name AS VARCHAR(255)) AS path
    FROM supplier s
    WHERE s.s_nationkey IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1, CAST(sh.path || ' -> ' || s.s_name AS VARCHAR(255))
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
AggregatedParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),
FinalResult AS (
    SELECT ch.c_custkey, ch.c_name, ps.total_cost, ns.supplier_count, ro.price_rank
    FROM CustomerOrderStats ch
    JOIN AggregatedParts ps ON ch.order_count > 0
    JOIN NationSummary ns ON ch.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ns.n_nationkey)
    LEFT JOIN RankedOrders ro ON ch.c_custkey = ro.o_orderkey
    WHERE ps.total_cost IS NOT NULL
)
SELECT fh.*, COALESCE(fh.total_cost * 0.1, 0) AS estimated_tax
FROM FinalResult fh
WHERE fh.order_count > (SELECT AVG(order_count) FROM CustomerOrderStats)
ORDER BY fh.total_cost DESC, fh.supplier_count DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
