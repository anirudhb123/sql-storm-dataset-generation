WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_supply_cost,
        STRING_AGG(s.s_name, ', ') AS suppliers_names,
        STRING_AGG(DISTINCT CONCAT(s.s_phone, ' (', s.s_name, ')'), '; ') AS supplier_contacts,
        CONCAT('Available: ', SUM(ps.ps_availqty), ' | Avg Cost: $', ROUND(AVG(ps.ps_supplycost), 2)) AS availability_info
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_mfgr, 
    availability_info, 
    suppliers_names, 
    supplier_contacts 
FROM 
    PartSupplierDetails p 
WHERE 
    total_available > 50 AND average_supply_cost < 100.00 
ORDER BY 
    p_name ASC;
