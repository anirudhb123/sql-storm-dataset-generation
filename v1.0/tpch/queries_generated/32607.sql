WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartSupplierSummary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(ps.total_avail_qty, 0) AS total_avail_qty,
    ps.avg_supply_cost,
    c.total_orders,
    c.total_spent,
    s.s_name,
    r.r_name
FROM part p
LEFT JOIN PartSupplierSummary ps ON ps.ps_partkey = p.p_partkey
LEFT JOIN CustomerOrderStats c ON c.total_orders > 0
LEFT JOIN supplier s ON s.s_suppkey = (SELECT ps_suppkey FROM partsupp WHERE ps_partkey = p.p_partkey ORDER BY ps_supplycost LIMIT 1)
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE (c.total_spent IS NULL OR c.total_spent > 500)
AND (p.p_retailprice BETWEEN 10.00 AND 100.00)
ORDER BY p.p_partkey
FETCH FIRST 50 ROWS ONLY;
