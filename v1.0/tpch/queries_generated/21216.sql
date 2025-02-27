WITH RankedSuppliers AS (
    SELECT s.s_supplycost, 
           s.s_suppkey, 
           s.s_name,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
DetailedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(ps.ps_availqty) AS total_availability,
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
           MAX(p.p_retailprice) AS max_price
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RecentOrders AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATEADD(MONTH, -6, GETDATE()) AND GETDATE()
    GROUP BY o.o_orderkey
),
SupplierPerformance AS (
    SELECT ns.n_nationkey,
           ns.n_name,
           ds.total_availability,
           ds.unique_suppliers,
           ds.max_price,
           COALESCE(rs.s_supplycost, 0) AS supply_cost,
           rs.rnk
    FROM nation ns
    LEFT JOIN DetailedParts ds ON ds.total_availability > 0
    LEFT JOIN RankedSuppliers rs ON ns.n_nationkey = rs.s_nationkey
)
SELECT sp.n_name,
       sp.total_availability,
       sp.unique_suppliers,
       sp.max_price,
       sp.supply_cost,
       rp.total_sales,
       CASE 
           WHEN sp.supply_cost IS NULL THEN 'Cost Not Available'
           WHEN sp.supply_cost < AVG(sp.supply_cost) OVER () THEN 'Below Average'
           ELSE 'Above Average'
       END AS cost_comparison,
       PERCENT_RANK() OVER (ORDER BY sp.total_availability) AS availability_rank
FROM SupplierPerformance sp
JOIN RecentOrders rp ON sp.max_price > 100.00 -- Arbitrary price condition
WHERE (sp.unique_suppliers > 5 OR sp.total_availability IS NULL)
  AND NOT EXISTS (SELECT 1 FROM lineitem l 
                  WHERE l.l_shipdate < CURRENT_DATE - INTERVAL '1 year' 
                    AND l.l_returnflag = 'Y')
ORDER BY sp.n_name, sp.supply_cost DESC;
