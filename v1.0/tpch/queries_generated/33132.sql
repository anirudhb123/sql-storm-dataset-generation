WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_size, p_retailprice, p_comment, 1 AS level
    FROM part
    WHERE p_size < 20

    UNION ALL

    SELECT p.p_partkey, p.p_name, p.p_size, p.p_retailprice, p.p_comment, ph.level + 1
    FROM part p
    JOIN PartHierarchy ph ON p.p_size = ph.p_size + 5
),
RegionSupplier AS (
    SELECT r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY c.c_custkey, c.c_name
),
PSSummary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT ph.p_name, ph.p_retailprice, ph.level, r.supplier_count, 
       cs.total_spent, ps.total_avail_qty, ps.avg_supply_cost
FROM PartHierarchy ph
JOIN RegionSupplier r ON r.supplier_count > 0
JOIN CustomerOrderSummary cs ON cs.total_spent > 1000
LEFT JOIN PSSummary ps ON ps.ps_partkey = ph.p_partkey
WHERE ph.p_retailprice - COALESCE(ps.avg_supply_cost, 0) > 0
ORDER BY ph.level DESC, cs.total_spent DESC
LIMIT 50;
