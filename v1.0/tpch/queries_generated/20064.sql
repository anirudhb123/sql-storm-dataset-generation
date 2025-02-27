WITH RECURSIVE OrderedData AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
), 
PriceAnalysis AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
), 
SupplierStats AS (
    SELECT s.s_suppkey, COUNT(DISTINCT ps.ps_partkey) AS part_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplier_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT od.o_orderkey, 
       od.o_orderdate, 
       CASE 
           WHEN od.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2) 
           THEN 'Above Average' 
           ELSE 'Below Average' 
       END AS price_comparison,
       COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
       ROW_NUMBER() OVER (PARTITION BY od.o_orderkey ORDER BY ps.total_supply_cost DESC) AS supplier_rank
FROM OrderedData od
LEFT JOIN SupplierStats s ON s.part_count = (SELECT COUNT(*) FROM partsupp WHERE ps_supplycost < 100 AND ps_partkey IN (SELECT p_partkey FROM part WHERE p_size BETWEEN 1 AND 20))
LEFT JOIN PriceAnalysis ps ON ps.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_availqty > 0 AND ps_supplycost IS NOT NULL)
WHERE od.o_orderdate >= DATE '2022-01-01' AND od.o_orderdate < DATE '2022-12-31'
  AND (s.total_supplier_cost IS NULL OR s.total_supplier_cost > 5000)
ORDER BY od.o_orderdate DESC, supplier_rank;
