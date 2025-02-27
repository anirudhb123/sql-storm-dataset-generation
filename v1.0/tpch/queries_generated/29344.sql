WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
TopSuppliers AS (
    SELECT rs.s_suppkey, rs.s_name, rs.s_nationkey, rs.s_acctbal
    FROM RankedSuppliers rs
    WHERE rs.rank <= 3
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand, p.p_type
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
),
SupplierPartDetails AS (
    SELECT ts.s_name, sp.p_name, sp.p_brand, sp.p_type
    FROM TopSuppliers ts
    JOIN SupplierParts sp ON ts.s_suppkey = sp.ps_suppkey
)
SELECT ts.s_name, GROUP_CONCAT(DISTINCT sp.p_name ORDER BY sp.p_name SEPARATOR ', ') AS part_names,
       COUNT(DISTINCT sp.p_type) AS unique_part_types
FROM SupplierPartDetails sp
JOIN TopSuppliers ts ON sp.s_name = ts.s_name
GROUP BY ts.s_name
ORDER BY unique_part_types DESC;
