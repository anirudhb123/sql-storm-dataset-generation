
WITH RECURSIVE SupplierRank AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
), 
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N' 
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
), 
RegionalSales AS (
    SELECT n.n_name, SUM(ho.total_value) AS regional_sales
    FROM nation n
    JOIN HighValueOrders ho ON n.n_nationkey = (SELECT DISTINCT c.c_nationkey FROM customer c WHERE c.c_custkey = ho.o_custkey) 
    GROUP BY n.n_name
), 
PartSupplierSummary AS (
    SELECT p.p_partkey, COUNT(DISTINCT ps.ps_suppkey) AS suppliers_count, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 2
)
SELECT 
    rs.n_name AS region_name,
    ps.p_partkey,
    ps.suppliers_count,
    ps.avg_supply_cost,
    CASE 
        WHEN rs.regional_sales IS NULL THEN 'No Sales'
        ELSE CAST(rs.regional_sales AS VARCHAR) END AS total_sales
FROM RegionalSales rs
FULL OUTER JOIN PartSupplierSummary ps ON ps.suppliers_count IS NULL OR ps.avg_supply_cost < 25.00
LEFT JOIN supplier s ON s.s_suppkey IN (SELECT s_suppkey FROM SupplierRank WHERE rank = 1)
WHERE rs.regional_sales IS NOT NULL OR rs.n_name IS NOT NULL
ORDER BY region_name, ps.p_partkey DESC;
