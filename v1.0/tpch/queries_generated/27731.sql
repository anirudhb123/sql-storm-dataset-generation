WITH RankedSuppliers AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_availqty DESC, ps.ps_supplycost ASC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredSuppliers AS (
    SELECT 
        supplier_name,
        part_name,
        ps_availqty,
        ps_supplycost
    FROM 
        RankedSuppliers
    WHERE 
        rank = 1
)
SELECT 
    fs.supplier_name,
    fs.part_name,
    fs.ps_availqty,
    fs.ps_supplycost,
    CONCAT('Supplier ', fs.supplier_name, ' offers Part ', fs.part_name, ' with availability of ', fs.ps_availqty, ' and supply cost of $', FORMAT(fs.ps_supplycost, 2)) AS detailed_info
FROM 
    FilteredSuppliers fs
WHERE 
    fs.ps_availqty > 50
ORDER BY 
    fs.ps_supplycost DESC;
