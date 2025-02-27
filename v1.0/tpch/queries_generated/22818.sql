WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
NationSuppliers AS (
    SELECT 
        n.n_name,
        n.n_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        STRING_AGG(s.s_name, ', ') AS supplier_names
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    ns.nation_count,
    ns.supplier_names,
    p.p_name,
    COALESCE(RANK() OVER (PARTITION BY r.r_regionkey ORDER BY p.total_cost DESC), 0) AS part_rank
FROM 
    region r
JOIN 
    (SELECT 
         n.n_regionkey,
         COUNT(DISTINCT n.n_nationkey) AS nation_count
     FROM 
         nation n
     JOIN 
         RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
     GROUP BY 
         n.n_regionkey) ns ON r.r_regionkey = ns.n.n_regionkey
LEFT JOIN 
    HighValueParts p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty IS NOT NULL)
WHERE 
    r.r_name LIKE 'Asia%' OR r.r_name IS NOT NULL
ORDER BY 
    part_rank DESC NULLS LAST;
