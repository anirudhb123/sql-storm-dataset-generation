WITH SupplierDetails AS (
    SELECT 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name, 
        s.s_acctbal, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_address, n.n_name, s.s_acctbal
),
AggregateStats AS (
    SELECT 
        AVG(total_value) AS avg_supply_value,
        MAX(total_value) AS max_supply_value,
        MIN(total_value) AS min_supply_value,
        SUM(part_count) AS total_parts_supplied
    FROM 
        SupplierDetails
)
SELECT 
    sd.s_name,
    sd.s_address,
    sd.nation_name,
    sd.s_acctbal,
    sd.part_count,
    sd.total_available_quantity,
    sd.total_value,
    as.avg_supply_value,
    as.max_supply_value,
    as.min_supply_value,
    as.total_parts_supplied
FROM 
    SupplierDetails sd, AggregateStats as
WHERE 
    sd.total_value > as.avg_supply_value
ORDER BY 
    sd.total_value DESC;
