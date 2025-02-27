WITH SupplierDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        s.s_address AS supplier_address,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(DISTINCT p.p_name, ', ') AS supplied_parts_names
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_address, n.n_name
)

SELECT 
    supplier_name,
    supplier_address,
    nation_name,
    total_parts_supplied,
    total_supply_cost,
    supplied_parts_names
FROM SupplierDetails
WHERE total_parts_supplied > 10
ORDER BY total_supply_cost DESC, supplier_name;
