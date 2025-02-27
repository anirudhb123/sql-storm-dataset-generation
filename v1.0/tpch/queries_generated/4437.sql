WITH RankedSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderstatus,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
NationHighValue AS (
    SELECT n.n_name, 
           SUM(ho.total_value) AS total_high_value
    FROM HighValueOrders ho
    JOIN customer c ON ho.o_orderkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_name
),
PartSupplierStatistics AS (
    SELECT p.p_partkey, 
           p.p_name, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT n.n_name, 
       phv.total_high_value, 
       p.p_name, 
       ps.s_name, 
       COALESCE(p_avg.avg_supply_cost, 0) AS avg_supply_cost,
       COALESCE(supplier_count, 0) AS supplier_count
FROM NationHighValue phv
FULL OUTER JOIN PartSupplierStatistics p_avg ON phv.total_high_value > 10000
JOIN RankedSuppliers rs ON rs.rnk = 1
JOIN supplier s ON rs.s_suppkey = s.s_suppkey
JOIN part p ON p.p_partkey = rs.ps_partkey
LEFT JOIN (
    SELECT ps_partkey, 
           COUNT(suppkey) AS supplier_count 
    FROM partsupp 
    GROUP BY ps_partkey
) AS ps ON p.p_partkey = ps.ps_partkey
WHERE phv.total_high_value IS NOT NULL OR supplier_count IS NOT NULL
ORDER BY phv.total_high_value DESC, p.p_name;
