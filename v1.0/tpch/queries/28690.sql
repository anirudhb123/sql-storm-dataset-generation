WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' from ', n.n_name, ' in ', r.r_name) AS supplier_info,
        SUBSTRING(s.s_comment, 1, 50) AS short_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
AggregateData AS (
    SELECT 
        supplier_info,
        SUM(ps_availqty) AS total_avail_qty,
        AVG(ps_supplycost) AS avg_supply_cost,
        STRING_AGG(short_comment, '; ') AS concatenated_comments
    FROM 
        SupplierDetails
    GROUP BY 
        supplier_info
)
SELECT 
    supplier_info,
    total_avail_qty,
    avg_supply_cost,
    CONCAT('Comments: ', concatenated_comments) AS detailed_comments
FROM 
    AggregateData
WHERE 
    avg_supply_cost < (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    total_avail_qty DESC;
