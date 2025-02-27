WITH SupplierAggregates AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationSupplier AS (
    SELECT 
        n.n_name,
        sa.s_name,
        sa.total_supply_cost,
        sa.total_parts,
        sa.part_names
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierAggregates sa ON s.s_suppkey = sa.s_suppkey
)
SELECT 
    n.n_name AS Nation,
    COUNT(*) AS total_suppliers,
    SUM(total_supply_cost) AS aggregate_supply_cost,
    AVG(total_parts) AS avg_parts_per_supplier,
    STRING_AGG(part_names, '; ') AS all_part_names
FROM 
    NationSupplier n
GROUP BY 
    n.n_name
ORDER BY 
    aggregate_supply_cost DESC;
