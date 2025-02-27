WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), PartStats AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type
), OrderStats AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
), FinalStats AS (
    SELECT si.s_name, si.nation_name, ps.p_name, ps.total_supply_cost, os.total_sales
    FROM SupplierInfo si
    JOIN PartStats ps ON si.s_suppkey = (SELECT ps.s_suppkey FROM partsupp ps WHERE ps.ps_partkey = ps.p_partkey ORDER BY ps.ps_supplycost LIMIT 1)
    JOIN OrderStats os ON os.o_orderkey = (SELECT o.o_orderkey FROM orders o LIMIT 1)
)
SELECT nation_name, COUNT(DISTINCT s_name) AS supplier_count, AVG(total_supply_cost) AS avg_supply_cost, SUM(total_sales) AS total_sales
FROM FinalStats
GROUP BY nation_name
ORDER BY total_sales DESC;
