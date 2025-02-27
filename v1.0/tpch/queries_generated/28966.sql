WITH SupplierInfo AS (
    SELECT s.s_name AS supplier_name, s.s_nationkey, n.n_name AS nation_name, COUNT(ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name, s.s_nationkey, n.n_name
),
PartInfo AS (
    SELECT p.p_name AS part_name, p.p_container, p.p_retailprice
    FROM part p
    WHERE LENGTH(p.p_name) > 20 AND p.p_retailprice > 50.00
),
OrderDetail AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
)
SELECT si.supplier_name, si.nation_name, 
       COUNT(DISTINCT pi.part_name) AS available_parts,
       AVG(od.total_value) AS average_order_value
FROM SupplierInfo si
LEFT JOIN PartInfo pi ON si.part_count > 0
LEFT JOIN OrderDetail od ON od.o_orderdate > '2022-01-01'
GROUP BY si.supplier_name, si.nation_name
ORDER BY average_order_value DESC, available_parts DESC
LIMIT 10;
