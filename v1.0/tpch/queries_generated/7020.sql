WITH SupplierPart AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_availqty, ps.ps_supplycost, p.p_name, p.p_brand
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 1000
),
RegionalSuppliers AS (
    SELECT n.n_name AS region_name, sp.s_suppkey, sp.s_name, sp.p_name, sp.p_brand, sp.ps_availqty, sp.ps_supplycost
    FROM SupplierPart sp
    JOIN nation n ON sp.s_nationkey = n.n_nationkey
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name IN ('ASIA', 'EUROPE'))
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING total_value > 50000
)
SELECT r.region_name, r.s_name, r.p_name, r.p_brand, r.ps_availqty, r.ps_supplycost, h.o_orderkey, h.o_orderdate, h.total_value
FROM RegionalSuppliers r
JOIN HighValueOrders h ON r.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name = r.p_name LIMIT 1) LIMIT 1)
ORDER BY r.region_name, h.total_value DESC
LIMIT 100;
