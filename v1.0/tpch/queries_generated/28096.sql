WITH SupplierOrders AS (
    SELECT s.s_name, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_name
),
RegionSummary AS (
    SELECT n.n_name AS nation_name, 
           r.r_name AS region_name, 
           SUM(CASE WHEN so.total_orders > 0 THEN so.total_orders ELSE 0 END) AS active_suppliers,
           SUM(so.total_revenue) AS total_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN SupplierOrders so ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_name = so.s_name)
    GROUP BY n.n_name, r.r_name
)
SELECT rs.region_name, 
       rs.nation_name, 
       rs.active_suppliers, 
       rs.total_revenue, 
       CONCAT('Nation: ', rs.nation_name, ', Active Suppliers: ', rs.active_suppliers) AS summary_description
FROM RegionSummary rs
WHERE rs.total_revenue > 100000
ORDER BY rs.total_revenue DESC;
