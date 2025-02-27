WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, STRING_AGG(CONCAT(p.p_name, ' (', ps.ps_availqty, ')'), ', ') AS part_info
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
FormattedSupplierList AS (
    SELECT s.s_suppkey, s.s_name, REPLACE(part_info, ' ', '_') AS formatted_part_info
    FROM RankedSuppliers s
),
SupplierCount AS (
    SELECT COUNT(*) AS supplier_count
    FROM FormattedSupplierList
)
SELECT fs.s_suppkey, fs.s_name, fs.formatted_part_info, sc.supplier_count
FROM FormattedSupplierList fs, SupplierCount sc
WHERE fs.s_name LIKE 'Supplier%'
ORDER BY fs.s_name;
