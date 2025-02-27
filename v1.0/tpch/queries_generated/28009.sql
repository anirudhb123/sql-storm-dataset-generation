WITH RankedSuppliers AS (
    SELECT 
        s.s_name AS supplier_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_availqty) DESC) AS availability_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, n.n_name
),
HighAvailabilitySuppliers AS (
    SELECT 
        supplier_name, 
        nation_name
    FROM 
        RankedSuppliers
    WHERE 
        availability_rank <= 3
)
SELECT 
    p.p_name AS part_name,
    COUNT(DISTINCT h.supplier_name) AS supplier_count,
    STRING_AGG(DISTINCT h.nation_name, ', ') AS nations_supplied
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    HighAvailabilitySuppliers h ON ps.ps_suppkey = (SELECT s.s_suppkey FROM supplier s WHERE s.s_name = h.supplier_name)
GROUP BY 
    p.p_name
ORDER BY 
    supplier_count DESC, 
    p.p_name;
