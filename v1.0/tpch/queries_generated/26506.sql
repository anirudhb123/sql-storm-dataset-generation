WITH PartSupplierDetails AS (
    SELECT 
        p.p_name,
        s.s_name,
        s.s_address,
        s.s_phone,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' - ', p.p_name) AS supplier_part_link,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size > 15 AND 
        ps.ps_availqty < 100
),
AggregatedData AS (
    SELECT 
        pd.p_name,
        COUNT(*) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(pd.comment_length) AS max_comment_length
    FROM 
        PartSupplierDetails pd
    GROUP BY 
        pd.p_name
)
SELECT 
    ad.p_name,
    ad.supplier_count,
    ad.total_available_qty,
    ad.avg_supply_cost,
    ad.max_comment_length,
    CONCAT('Total suppliers for ', ad.p_name, ': ', ad.supplier_count) AS supplier_summary
FROM 
    AggregatedData ad
ORDER BY 
    ad.total_available_qty DESC, 
    ad.avg_supply_cost ASC
LIMIT 10;
