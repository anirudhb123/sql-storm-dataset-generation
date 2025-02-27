WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_avail_qty, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, (SUM(ps.ps_availqty) * AVG(ps.ps_supplycost)) AS supplier_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING (SUM(ps.ps_availqty) * AVG(ps.ps_supplycost)) > 10000
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierRegionPerformance AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name, AVG(l.l_extendedprice) AS avg_extended_price, COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_name, r.r_name
)
SELECT 
    c.c_name AS customer_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(o.o_totalprice) AS total_spent,
    r.region_name,
    AVG(sp.avg_extended_price) AS regional_avg_price,
    hv.supplier_value
FROM CustomerOrderSummary c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN SupplierRegionPerformance sp ON sp.total_orders > 10
JOIN HighValueSuppliers hv ON hv.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 50))
GROUP BY c.c_name, r.region_name, hv.supplier_value
ORDER BY total_spent DESC, regional_avg_price DESC;
