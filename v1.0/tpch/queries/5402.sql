
WITH HighValueParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
), SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
), OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, COUNT(l.l_orderkey) AS total_lines
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING COUNT(l.l_orderkey) > 5
)
SELECT O.o_orderkey, O.o_orderdate, S.s_name, S.nation_name, S.region_name, HP.p_name, HP.total_supply_value
FROM OrderDetails O
JOIN HighValueParts HP ON O.o_orderkey = (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_partkey = HP.p_partkey
    LIMIT 1
)
JOIN SupplierDetails S ON S.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = HP.p_partkey
    ORDER BY ps.ps_supplycost DESC
    LIMIT 1
)
ORDER BY O.o_orderdate DESC, HP.total_supply_value DESC;
