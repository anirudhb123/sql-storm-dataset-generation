WITH SupplierPartCount AS (
    SELECT s.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name
),
TopSuppliers AS (
    SELECT s.s_name, sp.part_count
    FROM SupplierPartCount sp
    JOIN supplier s ON sp.s_name = s.s_name
    WHERE sp.part_count = (SELECT MAX(part_count) FROM SupplierPartCount)
),
PartNameSearch AS (
    SELECT DISTINCT p.p_name
    FROM part p
    WHERE UPPER(p.p_name) LIKE '%STEEL%' OR UPPER(p.p_name) LIKE '%ALUMINUM%'
),
OrderDetails AS (
    SELECT o.o_orderkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, c.c_name
)
SELECT ts.s_name, pns.p_name, od.c_name, od.total_revenue
FROM TopSuppliers ts
CROSS JOIN PartNameSearch pns
JOIN OrderDetails od ON od.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_name = ts.s_name
)
ORDER BY ts.s_name, pns.p_name, od.c_name;
