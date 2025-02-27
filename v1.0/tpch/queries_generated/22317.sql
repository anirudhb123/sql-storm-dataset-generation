WITH PartSupplier AS (
    SELECT ps.ps_partkey, 
           ps.ps_suppkey, 
           ps.ps_availqty, 
           ps.ps_supplycost, 
           p.p_name,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) as rn
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > ALL (SELECT AVG(p_retailprice) FROM part GROUP BY p_type))
), AvailableSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           p.p_name
    FROM supplier s
    JOIN PartSupplier ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > (SELECT AVG(ps_availqty) FROM PartSupplier)
), OrderDetails AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN DATEADD(DAY, -30, GETDATE()) AND GETDATE()
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING COUNT(DISTINCT l.l_partkey) > 5
), FinalSummary AS (
    SELECT os.o_orderkey,
           os.o_orderdate,
           os.total_revenue,
           CASE 
               WHEN os.total_revenue > (SELECT AVG(total_revenue) FROM OrderDetails) 
               THEN 'High Revenue' 
               ELSE 'Low Revenue' 
           END AS revenue_category,
           STRING_AGG(CONCAT(s.s_name, ' (', s.s_acctbal, ')'), ', ') AS suppliers
    FROM OrderDetails os
    LEFT JOIN AvailableSuppliers s ON os.o_orderkey % s.s_suppkey = 0
    GROUP BY os.o_orderkey, os.o_orderdate, os.total_revenue
)
SELECT f.o_orderkey, 
       f.o_orderdate, 
       f.total_revenue, 
       f.revenue_category, 
       COALESCE(f.suppliers, 'No suppliers available') AS suppliers 
FROM FinalSummary f
WHERE f.revenue_category = 'High Revenue'
ORDER BY f.total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
