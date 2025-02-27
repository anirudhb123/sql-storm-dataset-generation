WITH SupplierSummary AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_availqty) AS total_available_quantity, 
           AVG(ps.ps_supplycost) AS average_supply_cost,
           COUNT(DISTINCT p.p_partkey) AS unique_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopRegions AS (
    SELECT n.n_regionkey, 
           r.r_name, 
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_regionkey, r.r_name
    HAVING COUNT(DISTINCT o.o_orderkey) > 10
)
SELECT cs.c_name AS customer_name, 
       cs.total_spent AS customer_total_spent, 
       ss.s_name AS supplier_name, 
       ss.total_available_quantity AS supplier_qty_available, 
       tr.r_name AS region_name, 
       tr.order_count AS region_order_count,
       RANK() OVER (PARTITION BY tr.r_name ORDER BY cs.total_spent DESC) AS customer_rank_in_region
FROM CustomerOrders cs
JOIN SupplierSummary ss ON cs.order_count > 5
JOIN TopRegions tr ON ss.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100.00
)
WHERE cs.total_spent IS NOT NULL 
  AND tr.order_count IS NOT NULL 
ORDER BY tr.r_name, customer_rank_in_region;
