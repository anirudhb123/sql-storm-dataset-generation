
WITH StringAggregates AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_address,
        SUM(LENGTH(s.s_name)) AS total_name_length,
        SUM(LENGTH(s.s_address)) AS total_address_length,
        COUNT(DISTINCT s.s_nationkey) AS unique_nations,
        COUNT(DISTINCT p.p_partkey) AS total_parts,
        LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS part_names
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address
),
RankedSuppliers AS (
    SELECT 
        s.*, 
        RANK() OVER (ORDER BY total_name_length DESC, total_address_length ASC) AS name_length_rank,
        DENSE_RANK() OVER (ORDER BY unique_nations DESC) AS unique_nations_rank
    FROM 
        StringAggregates s
)
SELECT 
    r.s_suppkey, 
    r.s_name, 
    r.s_address, 
    r.total_name_length, 
    r.total_address_length, 
    r.unique_nations, 
    r.total_parts, 
    r.part_names, 
    r.name_length_rank, 
    r.unique_nations_rank
FROM 
    RankedSuppliers r
WHERE 
    r.unique_nations > 1
ORDER BY 
    r.name_length_rank, r.unique_nations_rank;
