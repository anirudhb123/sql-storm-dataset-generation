WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS ranking
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.s_acctbal
    FROM RankedSuppliers rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.ranking <= 3
)
SELECT 
    region_name,
    nation_name,
    STRING_AGG(supplier_name, ', ') AS top_suppliers,
    SUM(s_acctbal) AS total_acctbal
FROM TopSuppliers
GROUP BY region_name, nation_name
ORDER BY region_name, total_acctbal DESC;
