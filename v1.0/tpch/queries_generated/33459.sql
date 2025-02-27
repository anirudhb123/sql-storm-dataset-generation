WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
),

OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate <= '2023-12-31'
    GROUP BY o.o_orderkey
),

PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available_quantity, 
           AVG(ps.ps_supplycost) AS average_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)

SELECT ph.s_name, 
       ps.p_name,
       COALESCE(ps.total_available_quantity, 0) AS available_quantity,
       os.total_revenue,
       ph.level
FROM SupplierHierarchy ph
JOIN PartSupplierDetails ps ON ph.s_suppkey = ps.p_partkey
LEFT JOIN OrderStats os ON os.o_orderkey = ps.p_partkey
WHERE ps.average_supply_cost < 5000.00
ORDER BY ph.level DESC, available_quantity DESC;
