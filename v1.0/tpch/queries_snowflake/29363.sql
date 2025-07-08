
WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        LEFT(s.s_comment, 50) AS short_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, r.r_name, s.s_comment
),
Ranking AS (
    SELECT 
        si.*,
        RANK() OVER (PARTITION BY si.region_name ORDER BY si.total_supply_cost DESC) AS rank_by_cost,
        RANK() OVER (PARTITION BY si.region_name ORDER BY si.part_count DESC) AS rank_by_parts
    FROM 
        SupplierInfo si
)
SELECT 
    r.region_name,
    COUNT(*) AS supplier_count,
    SUM(CASE WHEN r.rank_by_cost <= 3 THEN r.total_supply_cost ELSE 0 END) AS top3_supply_cost,
    SUM(CASE WHEN r.rank_by_parts <= 3 THEN r.part_count ELSE 0 END) AS top3_part_count,
    AVG(r.s_acctbal) AS avg_acct_balance,
    LISTAGG(r.short_comment, '; ') WITHIN GROUP (ORDER BY r.s_suppkey) AS combined_comments
FROM 
    Ranking r
GROUP BY 
    r.region_name
ORDER BY 
    supplier_count DESC, r.region_name;
