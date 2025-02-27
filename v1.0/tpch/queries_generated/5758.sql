WITH SupplierStats AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_availqty) AS total_available_quantity,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_orderdate
),
RegionNation AS (
    SELECT r.r_name AS region_name,
           n.n_name AS nation_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name, n.n_name
)
SELECT ss.s_name AS supplier_name,
       os.o_orderkey AS order_identifier,
       os.total_revenue AS revenue_generated,
       rn.region_name,
       rn.nation_name,
       rn.supplier_count,
       ss.total_available_quantity,
       ss.total_cost
FROM SupplierStats ss
JOIN OrderDetails os ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 100.00))
JOIN RegionNation rn ON ss.s_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = rn.nation_name))
WHERE os.total_revenue > (SELECT AVG(total_revenue) FROM OrderDetails)
ORDER BY ss.total_available_quantity DESC, os.total_revenue DESC
LIMIT 50;
