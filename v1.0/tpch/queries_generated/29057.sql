WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
BestSuppliers AS (
    SELECT 
        supplier_rank,
        s_suppkey,
        s_name,
        nation_name,
        p_name,
        ps_supplycost
    FROM 
        RankedSuppliers
    WHERE 
        supplier_rank <= 5
)
SELECT 
    CONCAT('Supplier: ', s_name, ', Nation: ', nation_name, ', Part: ', p_name, ', Cost: $', FORMAT(ps_supplycost, 2)) AS supplier_info
FROM 
    BestSuppliers
ORDER BY 
    nation_name, ps_supplycost;
