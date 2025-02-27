WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation,
        COUNT(ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name
),
StringProcessing AS (
    SELECT 
        r.r_name AS region_name,
        STRING_AGG(CONCAT(s.s_name, ': ', parts_supplied, ' parts, $', total_supply_cost), '; ') AS supplier_summary
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.nation = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    region_name,
    REGEXP_REPLACE(supplier_summary, '[^a-zA-Z0-9 ,;:.$]', '', 'g') AS cleaned_supplier_summary
FROM 
    StringProcessing;
