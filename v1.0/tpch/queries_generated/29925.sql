WITH EnrichedParts AS (
    SELECT 
        p.p_partkey,
        REPLACE(p.p_name, ' ', '-') AS modified_name,
        SUBSTRING(p.p_comment, 1, 10) AS brief_comment,
        CONCAT('Brand: ', p.p_brand, ', Type: ', p.p_type) AS product_info
    FROM 
        part p
),
SupplierSummary AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(s.s_acctbal) AS average_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(ss.total_parts) AS region_parts_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        SupplierSummary ss ON n.n_nationkey = ss.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    ep.modified_name,
    ep.brief_comment,
    tr.r_name,
    tr.region_parts_count,
    ss.average_account_balance
FROM 
    EnrichedParts ep
JOIN 
    SupplierSummary ss ON ep.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (
        SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = ss.s_nationkey
    ))
JOIN 
    TopRegions tr ON ss.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = tr.r_regionkey)
ORDER BY 
    tr.region_parts_count DESC, ep.modified_name;
