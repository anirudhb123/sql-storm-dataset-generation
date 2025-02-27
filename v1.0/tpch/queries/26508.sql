WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_type,
    p.p_size,
    p.supplier_count,
    p.total_supply_cost,
    p.suppliers,
    s.s_name AS supplier_name,
    s.nation,
    s.part_count,
    s.total_supply_cost AS supplier_total_supply_cost
FROM 
    RankedParts p
JOIN 
    RankedSuppliers s ON p.supplier_count = s.part_count
WHERE 
    p.total_supply_cost > 10000 AND s.total_supply_cost < 5000
ORDER BY 
    p.supplier_count DESC, s.part_count ASC;
