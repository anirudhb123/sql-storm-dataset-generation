WITH RegionSupplier AS (
    SELECT r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, ps.total_value
    FROM PartSupplier ps
    JOIN part p ON ps.p_partkey = p.p_partkey
    ORDER BY ps.total_value DESC
    LIMIT 10
)
SELECT r.r_name, ts.p_name, ts.total_value, rs.supplier_count
FROM RegionSupplier rs
JOIN TopParts ts ON rs.supplier_count > 5
ORDER BY total_value DESC, r.r_name;
