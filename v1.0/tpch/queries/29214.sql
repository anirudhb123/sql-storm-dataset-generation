WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(p.p_name, ' - ', s.s_name, ': Available Qty = ', ps.ps_availqty, ', Supply Cost = ', ps.ps_supplycost) AS details
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
AggregatedSupply AS (
    SELECT 
        p_partkey,
        COUNT(*) AS supplier_count,
        SUM(ps_supplycost) AS total_supply_cost,
        STRING_AGG(details, '; ') AS supplier_details
    FROM 
        PartSupplierDetails
    GROUP BY 
        p_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    a.supplier_count,
    a.total_supply_cost,
    a.supplier_details
FROM 
    part p
JOIN 
    AggregatedSupply a ON p.p_partkey = a.p_partkey
WHERE 
    a.supplier_count > 1
ORDER BY 
    a.total_supply_cost DESC;
