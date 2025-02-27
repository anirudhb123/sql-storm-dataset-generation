WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        p.p_type,
        ps.ps_supplycost,
        ps.ps_availqty,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' of type ', p.p_type, ' costing ', ROUND(ps.ps_supplycost, 2)) AS supply_details
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighSupplyParts AS (
    SELECT 
        sp.s_suppkey,
        sp.supply_details,
        ROW_NUMBER() OVER (PARTITION BY sp.s_suppkey ORDER BY sp.ps_supplycost DESC) as rn
    FROM 
        SupplierParts sp
    WHERE 
        sp.ps_availqty > 50
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT hsp.s_suppkey) AS total_suppliers,
    STRING_AGG(DISTINCT hsp.supply_details, '; ') AS supplier_info
FROM 
    HighSupplyParts hsp
JOIN 
    supplier s ON hsp.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    hsp.rn = 1
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_suppliers DESC;
