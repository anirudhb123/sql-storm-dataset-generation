
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name, n.n_regionkey
),
SuppliersWithComments AS (
    SELECT 
        r.r_name AS region_name,
        RankedSuppliers.s_suppkey,
        RankedSuppliers.s_name,
        RankedSuppliers.s_address,
        RankedSuppliers.nation_name,
        RankedSuppliers.part_count,
        RankedSuppliers.total_supplycost,
        s.s_comment
    FROM 
        RankedSuppliers
    JOIN 
        supplier s ON RankedSuppliers.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        RankedSuppliers.rank <= 3
)
SELECT 
    region_name,
    s_suppkey,
    s_name,
    s_address,
    nation_name,
    part_count,
    total_supplycost,
    LISTAGG(s_comment, '; ') WITHIN GROUP (ORDER BY s_suppkey) AS comments
FROM 
    SuppliersWithComments
GROUP BY 
    region_name, s_suppkey, s_name, s_address, nation_name, part_count, total_supplycost
ORDER BY 
    region_name, total_supplycost DESC;
