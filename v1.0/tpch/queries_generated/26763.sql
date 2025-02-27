WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        ps.ps_supplycost,
        ps.ps_availqty,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with brand ', p.p_brand, ' in ', p.p_container) AS supply_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
AggregatedSupply AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT p.partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(DISTINCT supply_info, '; ') AS detailed_supply_info
    FROM 
        SupplierParts s
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    a.s_suppkey,
    a.s_name,
    a.total_parts,
    a.total_available_quantity,
    a.total_supply_cost,
    a.detailed_supply_info
FROM 
    AggregatedSupply a
WHERE 
    a.total_available_quantity > 100
ORDER BY 
    a.total_supply_cost DESC;
