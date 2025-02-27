WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_account_balance,
        STRING_AGG(s.s_comment, ', ') AS combined_comments
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
region_summary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS total_nations,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nations_list
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    ss.s_suppkey,
    ss.s_name,
    rs.r_regionkey,
    rs.r_name,
    ss.total_parts,
    ss.total_supply_cost,
    ss.avg_account_balance,
    ss.combined_comments,
    rs.total_nations,
    rs.nations_list
FROM 
    supplier_summary ss
JOIN 
    nation n ON ss.s_nationkey = n.n_nationkey
JOIN 
    region_summary rs ON n.n_regionkey = rs.r_regionkey
ORDER BY 
    ss.total_supply_cost DESC, ss.total_parts DESC;
