WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, 
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), FilteredOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderstatus,
           CASE 
               WHEN o.o_orderstatus = 'F' THEN 'Finalized'
               WHEN o.o_orderstatus IS NULL THEN 'Unknown'
               ELSE 'In Process' 
           END AS order_status_desc
    FROM orders o
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
), TopNations AS (
    SELECT n.n_regionkey, n.n_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_regionkey, n.n_name
    HAVING COUNT(s.s_suppkey) > 5
)
SELECT t.n_name AS nation_name, 
       COUNT(DISTINCT f.o_orderkey) AS total_orders,
       SUM(f.o_totalprice) AS total_revenue,
       STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM TopNations t
LEFT JOIN RankedSuppliers r ON t.n_regionkey = r.s_nationkey 
LEFT JOIN FilteredOrders f ON f.o_custkey = (SELECT c.c_custkey 
                                                FROM customer c 
                                                WHERE c.c_nationkey = t.n_regionkey 
                                                  AND c.c_acctbal > 1000
                                                FETCH FIRST 1 ROW ONLY) 
LEFT JOIN supplier s ON r.s_suppkey = s.s_suppkey AND r.supplier_rank = 1
WHERE r.total_supply_value IS NOT NULL 
GROUP BY t.n_name
HAVING COUNT(DISTINCT f.o_orderkey) > 5
  AND SUM(f.o_totalprice) > (SELECT AVG(o.o_totalprice) 
                               FROM orders o 
                               WHERE o.o_orderstatus = 'F')
ORDER BY total_revenue DESC NULLS LAST;
