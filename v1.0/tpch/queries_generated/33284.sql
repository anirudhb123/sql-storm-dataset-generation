WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           p.p_partkey, p.p_name, 
           ps.ps_availqty, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
),
CustomerOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
RankedSuppliers AS (
    SELECT sc.s_suppkey, sc.s_name, sc.p_partkey, sc.p_name, 
           sc.ps_availqty, sc.ps_supplycost, 
           COALESCE((SELECT SUM(ps1.ps_availqty) 
                     FROM partsupp ps1 
                     WHERE ps1.ps_partkey = sc.p_partkey), 0) AS total_avail_qty,
           RANK() OVER (ORDER BY sc.ps_supplycost ASC) AS rank_cost,
           RANK() OVER (PARTITION BY sc.p_partkey ORDER BY sc.ps_availqty DESC) AS rank_avail
    FROM SupplyChain sc
)
SELECT n.n_name, 
       SUM(r.total_revenue) AS total_sales, 
       COUNT(DISTINCT r.o_orderkey) AS order_count,
       COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       AVG(r.total_revenue) AS avg_order_value 
FROM CustomerOrders r
JOIN customer c ON r.o_custkey = c.c_custkey
JOIN supplier s ON c.c_nationkey = s.s_nationkey
JOIN rankedsuppliers rs ON s.s_suppkey = rs.s_suppkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
WHERE n.n_name IS NOT NULL
  AND s.s_acctbal IS NOT NULL 
  AND rs.total_avail_qty > 0
GROUP BY n.n_name
HAVING SUM(r.total_revenue) > 10000
ORDER BY avg_order_value DESC;
