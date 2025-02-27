WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, p.p_name, p.p_brand, p.p_type
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
TotalOrderValue AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
RankedSuppliers AS (
    SELECT sd.s_suppkey, sd.s_name, sd.s_acctbal, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY sd.region_name ORDER BY SUM(ps.ps_availqty * ps.ps_supplycost) DESC) AS supplier_rank
    FROM SupplierDetails sd
    JOIN PartSupplier ps ON sd.s_suppkey = ps.ps_suppkey
    GROUP BY sd.s_suppkey, sd.s_name, sd.s_acctbal, sd.nation_name, sd.region_name
)
SELECT rs.region_name, rs.s_name, rs.total_supply_cost, tov.total_value
FROM RankedSuppliers rs
JOIN TotalOrderValue tov ON rs.s_suppkey = tov.o_custkey
WHERE rs.supplier_rank <= 5
ORDER BY rs.region_name, rs.total_supply_cost DESC, tov.total_value DESC;
