
WITH PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        CONCAT(s.s_address, ', ', n.n_name) AS supplier_location,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        p.p_size IN (10, 20, 30)
        AND p.p_retailprice BETWEEN 100.00 AND 500.00
),
RegionCounts AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        r.r_name
)
SELECT 
    rc.part_count,
    psi.supplier_location,
    rc.r_name,
    STRING_AGG(psi.p_name, ', ') AS part_names,
    SUM(psi.ps_supplycost) AS total_supplycost
FROM 
    PartSupplierInfo psi
JOIN 
    RegionCounts rc ON TRUE
GROUP BY 
    rc.r_name, psi.supplier_location, rc.part_count
HAVING 
    SUM(psi.ps_supplycost) > 1000
ORDER BY 
    rc.r_name, total_supplycost DESC;
