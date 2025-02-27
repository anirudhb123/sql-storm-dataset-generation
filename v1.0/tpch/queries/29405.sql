WITH SupplierDetails AS (
    SELECT s.s_name, s.s_nationkey, n.n_name AS nation_name, 
           STRING_AGG(DISTINCT p.p_name, ', ') AS part_names, 
           COUNT(DISTINCT ps.ps_partkey) AS total_parts,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 100.00 
    GROUP BY s.s_name, s.s_nationkey, n.n_name
), OrderDetails AS (
    SELECT o.o_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
)
SELECT sd.s_name, sd.nation_name, sd.part_names, sd.total_parts, 
       od.order_count, od.total_revenue
FROM SupplierDetails sd
LEFT JOIN OrderDetails od ON sd.s_nationkey = od.o_custkey
ORDER BY sd.nation_name, sd.total_supply_cost DESC;
