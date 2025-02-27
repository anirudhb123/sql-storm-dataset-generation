WITH RecursivePartInfo AS (
    SELECT 
        p.partkey,
        p.p_name,
        p.p_mfgr,
        CONCAT('Part: ', p.p_name, ', Manufacturer: ', p.p_mfgr) AS part_info,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_mfgr) AS mfgr_length
    FROM part p
    WHERE p.p_type LIKE 'Standard%'
    
    UNION ALL
    
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_mfgr,
        CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Manufacturer: ', p.p_mfgr) AS part_info,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_mfgr) AS mfgr_length
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_type LIKE 'Standard%'
),
AggregatedData AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(*) AS total_parts,
        SUM(name_length) AS total_name_length,
        SUM(mfgr_length) AS total_mfgr_length,
        AVG(name_length) AS avg_name_length,
        AVG(mfgr_length) AS avg_mfgr_length
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN RecursivePartInfo rpi ON s.s_suppkey = rpi.partkey
    GROUP BY r.r_name
)
SELECT 
    region_name,
    total_parts,
    total_name_length,
    total_mfgr_length,
    avg_name_length,
    avg_mfgr_length,
    CASE 
        WHEN avg_name_length > 20 THEN 'Long Names'
        ELSE 'Short Names'
    END AS name_length_category
FROM AggregatedData
ORDER BY region_name ASC, total_parts DESC;
