WITH PartSupplierStats AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        COUNT(ps.ps_suppkey) AS supplier_count, 
        AVG(s.s_acctbal) AS avg_supplier_acctbal,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
),
RegionNationStats AS (
    SELECT 
        r.r_name AS region_name, 
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nation_names
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    ps.supplier_count, 
    ps.avg_supplier_acctbal, 
    ps.supplier_names, 
    rn.region_name, 
    rn.nation_count, 
    rn.nation_names
FROM 
    PartSupplierStats ps
JOIN 
    supplier s ON ps.supplier_names LIKE '%' || s.s_name || '%'
JOIN 
    (SELECT 
         s.s_nationkey, 
         r.r_name 
     FROM 
         supplier s 
     JOIN 
         nation n ON s.s_nationkey = n.n_nationkey 
     JOIN 
         region r ON n.n_regionkey = r.r_regionkey) rn
ON 
    s.s_nationkey = rn.s_nationkey
ORDER BY 
    ps.supplier_count DESC, 
    p.p_name ASC;
