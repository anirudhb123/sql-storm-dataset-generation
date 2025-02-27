WITH SupplierSummary AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RegionNation AS (
    SELECT n.n_nationkey, 
           n.n_name, 
           r.r_regionkey, 
           r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
OrderLineDetails AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           COUNT(DISTINCT l.l_partkey) AS product_count,
           o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    rn.r_name AS region,
    s.s_name AS supplier_name,
    ss.total_supply_cost AS supplier_total_cost,
    od.revenue AS order_revenue,
    od.product_count AS products_in_order
FROM SupplierSummary ss
JOIN regionnation rn ON ss.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_type LIKE 'SMALLANIMALS%')
)
LEFT JOIN OrderLineDetails od ON ss.s_suppkey = od.o_orderkey
WHERE ss.total_supply_cost > (
    SELECT AVG(total_supply_cost) 
    FROM SupplierSummary
    WHERE total_supply_cost IS NOT NULL
)
ORDER BY od.revenue DESC NULLS LAST
LIMIT 100;
