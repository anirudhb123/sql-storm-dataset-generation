WITH SupplierStats AS (
    SELECT s.s_suppkey, 
           SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),

OrderDetails AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(l.l_linenumber) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
      AND o.o_orderdate < '2023-12-31'
    GROUP BY o.o_orderkey
),

RegionStats AS (
    SELECT r.r_regionkey, 
           r.r_name, 
           COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)

SELECT r.r_name,
       ss.s_suppkey,
       ss.total_avail_qty,
       ss.avg_supply_cost,
       od.total_price,
       od.item_count,
       rs.nation_count,
       CASE 
           WHEN od.total_price IS NULL THEN 'No Orders'
           WHEN ss.total_avail_qty / NULLIF(od.item_count, 0) > 100 THEN 'High Availability'
           ELSE 'Check Supply' 
       END AS supply_status
FROM RegionStats rs
JOIN SupplierStats ss ON rs.nation_count > 1
FULL OUTER JOIN OrderDetails od ON ss.s_suppkey = od.o_orderkey
ORDER BY r.r_name, ss.avg_supply_cost DESC;
