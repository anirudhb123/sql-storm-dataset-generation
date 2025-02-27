WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           COUNT(l.l_orderkey) AS lineitem_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
), HighestOrderPerCustomer AS (
    SELECT cust.c_custkey, cust.c_name, MAX(cust.o_totalprice) AS max_order_total
    FROM CustomerOrders cust
    WHERE cust.o_orderdate >= DATE '2022-01-01'
    GROUP BY cust.c_custkey, cust.c_name
), SupplementaryData AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name, r.r_comment
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
), SupplierPerformance AS (
    SELECT rs.s_suppkey, rs.s_name, rs.total_supply_cost,
           COALESCE(hop.max_order_total, 0) AS max_order_value
    FROM RankedSuppliers rs
    LEFT JOIN HighestOrderPerCustomer hop ON rs.s_nationkey = hop.c_custkey
)
SELECT sp.nation_name, sp.region_name, sp.s_name,
       SUM(sp.total_supply_cost) OVER (PARTITION BY sp.nation_name ORDER BY sp.total_supply_cost) AS cumulative_supply_cost,
       CASE 
           WHEN sp.max_order_value IS NULL THEN 'No Orders'
           ELSE 'Order Value Exists'
       END AS order_status
FROM SupplierPerformance sp
JOIN SupplementaryData sd ON sp.s_nationkey = sd.n_nationkey
WHERE (sp.max_order_value > 1000 OR sp.max_order_value IS NULL)
ORDER BY sp.nation_name, cumulative_supply_cost DESC;
