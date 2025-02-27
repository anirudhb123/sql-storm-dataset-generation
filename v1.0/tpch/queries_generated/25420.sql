WITH Supplier_Stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
Region_Nation_Supplier AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        ss.s_name AS supplier_name,
        ss.part_count,
        ss.total_supplycost,
        ss.part_names,
        ss.avg_acctbal
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        Supplier_Stats ss ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_name = ss.s_name)
)
SELECT 
    region_name,
    nation_name,
    supplier_name,
    part_count,
    total_supplycost,
    part_names,
    avg_acctbal
FROM 
    Region_Nation_Supplier
WHERE 
    part_count > 5 AND 
    total_supplycost > 1000
ORDER BY 
    region_name, nation_name, total_supplycost DESC;
