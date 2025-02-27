WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(p.p_name, ' from ', s.s_name) AS part_supplier_info,
        LEFT(p.p_comment || ' - ' || s.s_comment, 50) AS combined_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
AggregatedData AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        STRING_AGG(part_supplier_info, '; ') AS supplier_info_list,
        STRING_AGG(combined_comment, '; ') AS combined_comments
    FROM 
        PartSupplierDetails p
    GROUP BY 
        p.p_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    a.supplier_count,
    a.total_avail_qty,
    ROUND(a.avg_supply_cost, 2) AS average_supply_cost,
    a.supplier_info_list,
    a.combined_comments
FROM 
    part p
JOIN 
    AggregatedData a ON p.p_partkey = a.p_partkey
WHERE 
    a.total_avail_qty > 0
ORDER BY 
    a.avg_supply_cost DESC, 
    a.supplier_count DESC
LIMIT 10;
