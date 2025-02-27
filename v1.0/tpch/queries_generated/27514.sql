WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        (ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with quantity ', CAST(ps.ps_availqty AS VARCHAR), ' and total supply value of $', FORMAT((ps.ps_supplycost * ps.ps_availqty), 2)) AS detailed_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
), NationalSupplierSummary AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name AS region_name,
    n.nation_name,
    ns.total_suppliers,
    ns.avg_supply_cost,
    ns.total_available_quantity,
    STRING_AGG(spd.detailed_comment, '; ') AS supplier_part_details
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    NationalSupplierSummary ns ON n.n_name = ns.nation_name
LEFT JOIN 
    SupplierPartDetails spd ON n.n_name = SUBSTRING(spd.supplier_name, 1, LENGTH(n.n_name))  -- Simplified join condition for demonstration
GROUP BY 
    r.r_name, n.nation_name, ns.total_suppliers, ns.avg_supply_cost, ns.total_available_quantity
ORDER BY 
    r.r_name, n.nation_name;
