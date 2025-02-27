WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        COUNT(ps.ps_partkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        CASE 
            WHEN SUM(ps.ps_availqty) > 0 THEN 'Available'
            ELSE 'Unavailable'
        END AS availability_status
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
HighValueParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.supplier_count,
        rp.suppliers,
        rp.total_available_quantity,
        rp.total_supply_cost,
        rp.availability_status,
        ROUND(rp.total_supply_cost / NULLIF(rp.total_available_quantity, 0), 2) AS avg_supply_cost_per_unit
    FROM 
        RankedParts rp
    WHERE 
        rp.total_supply_cost > 10000
    ORDER BY 
        avg_supply_cost_per_unit DESC
)
SELECT 
    hvp.p_partkey,
    hvp.p_name,
    hvp.p_brand,
    hvp.supplier_count,
    hvp.suppliers,
    hvp.total_available_quantity,
    hvp.total_supply_cost,
    hvp.avg_supply_cost_per_unit,
    REGEXP_REPLACE(hvp.availability_status, 'Available', 'In Stock') AS availability_status
FROM 
    HighValueParts hvp
WHERE 
    hvp.supplier_count > 1
LIMIT 10;
