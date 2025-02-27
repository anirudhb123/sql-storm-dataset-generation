WITH RECURSIVE SupplyCostCTE AS (
    SELECT ps.partkey, ps.suppkey, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY ps.partkey ORDER BY ps.ps_supplycost ASC) as rn
    FROM partsupp ps
    WHERE ps.ps_supplycost IS NOT NULL
), 
TotalCustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F') 
    GROUP BY c.c_custkey, c.c_name
), 
HighSpenders AS (
    SELECT *,
           CASE 
               WHEN total_spent > 10000 THEN 'High Roller'
               ELSE 'Regular'
           END AS spender_type
    FROM TotalCustomerOrders
), 
SupplierRegion AS (
    SELECT s.s_suppkey, r.r_name AS region_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey, r.r_name
)
SELECT h.c_name,
       COALESCE(s.region_name, 'Unknown') AS supplier_region,
       COALESCE(min_cost, 0) AS min_supply_cost,
       COALESCE(max_cost, 0) AS max_supply_cost,
       h.spender_type,
       MAX(s.order_count) AS total_orders
FROM HighSpenders h
LEFT JOIN (
    SELECT partkey, MIN(ps_supplycost) AS min_cost, MAX(ps_supplycost) AS max_cost
    FROM SupplyCostCTE
    WHERE rn = 1
    GROUP BY partkey
) AS sc ON h.c_custkey = sc.partkey
LEFT JOIN SupplierRegion s ON s.s_suppkey = (SELECT ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = sc.partkey ORDER BY ps.ps_supplycost LIMIT 1)
GROUP BY h.c_name, s.region_name, min_cost, max_cost, h.spender_type
ORDER BY total_orders DESC, h.c_name ASC;
