
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        p.p_name,
        ps.ps_availqty,
        RANK() OVER (PARTITION BY n.n_name ORDER BY ps.ps_supplycost DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_brand LIKE 'Brand#%'
)
SELECT 
    r.nation_name,
    COUNT(*) AS total_suppliers,
    AVG(r.ps_availqty) AS avg_availability,
    LISTAGG(r.s_name, ', ') AS supplier_names
FROM 
    RankedSuppliers r
WHERE 
    r.supplier_rank <= 3
GROUP BY 
    r.nation_name
ORDER BY 
    total_suppliers DESC;
