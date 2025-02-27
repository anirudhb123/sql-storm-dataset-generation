WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        p.p_name,
        ps.ps_supplycost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredSuppliers AS (
    SELECT 
        nation_name,
        p_name,
        s_name,
        s_address,
        ps_supplycost
    FROM 
        RankedSuppliers
    WHERE 
        rank <= 3
)
SELECT 
    f.nation_name,
    f.p_name,
    STRING_AGG(CONCAT(f.s_name, ' (', f.s_address, ')'), ', ') AS supplier_info,
    MIN(f.ps_supplycost) AS min_supplycost,
    MAX(f.ps_supplycost) AS max_supplycost,
    AVG(f.ps_supplycost) AS avg_supplycost
FROM 
    FilteredSuppliers f
GROUP BY 
    f.nation_name,
    f.p_name
ORDER BY 
    f.nation_name, 
    f.p_name;
