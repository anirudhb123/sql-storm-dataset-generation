WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 5000
    
    UNION ALL
    
    SELECT ch.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_custkey = ch.c_custkey + 1
    WHERE c.c_acctbal > 5000
),
RegionSuppliers AS (
    SELECT r.r_name, COUNT(s.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierPartDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) as total_qty, AVG(ps.ps_supplycost) as avg_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    ch.c_name,
    ch.level,
    r.supplier_count,
    h.total_revenue,
    CASE 
        WHEN sd.total_qty IS NULL THEN 'No Parts Available'
        ELSE CONCAT('Available Qty: ', sd.total_qty, ', Avg Cost: ', sd.avg_cost)
    END AS part_details
FROM CustomerHierarchy ch
JOIN RegionSuppliers r ON r.supplier_count > 5
LEFT JOIN HighValueOrders h ON h.o_orderkey = ch.c_custkey
LEFT JOIN SupplierPartDetails sd ON ch.c_custkey = sd.ps_partkey
ORDER BY ch.level, r.supplier_count DESC;
