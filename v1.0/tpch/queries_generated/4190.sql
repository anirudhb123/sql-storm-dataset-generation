WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
),
TotalSales AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SupplierCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_brand,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    COALESCE(SUM(ts.total_sales), 0) AS total_sales,
    COALESCE(SUM(sc.total_supply_cost), 0) AS total_supply_cost,
    AVG(o.o_totalprice) AS avg_order_value,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN customer c ON c.c_nationkey = s.s_nationkey
LEFT JOIN RankedOrders ro ON c.c_custkey = ro.o_orderkey
LEFT JOIN TotalSales ts ON ro.o_orderkey = ts.l_orderkey
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN orders o ON ro.o_orderkey = o.o_orderkey
WHERE p.p_size > 20 
  AND (s.s_acctbal IS NULL OR s.s_acctbal > 1000.00)
GROUP BY p.p_partkey, p.p_name, p.p_brand, r.r_name
HAVING COUNT(DISTINCT ro.o_orderkey) > 5
ORDER BY total_sales DESC, avg_order_value DESC;
