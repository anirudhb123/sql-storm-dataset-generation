WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT r.r_name, ns.n_name, rs.s_suppkey, rs.s_name, SUM(rs.ps_availqty * rs.ps_supplycost) AS total_value
    FROM RankedSuppliers rs
    JOIN nation ns ON s.s_nationkey = ns.n_nationkey
    JOIN region r ON ns.n_regionkey = r.r_regionkey
    WHERE rs.rank <= 3
    GROUP BY r.r_name, ns.n_name, rs.s_suppkey, rs.s_name
),
FinalResults AS (
    SELECT r_name, n_name, SUM(total_value) AS total_supplier_value
    FROM TopSuppliers
    GROUP BY r_name, n_name
)
SELECT fr.r_name, fr.n_name, fr.total_supplier_value
FROM FinalResults fr
ORDER BY fr.total_supplier_value DESC
LIMIT 10;
