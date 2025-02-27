WITH SupplierDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        s.s_address AS supplier_address,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_address, n.n_name
),
HighestPartCount AS (
    SELECT 
        supplier_name,
        supplier_address,
        nation_name,
        part_count,
        RANK() OVER (ORDER BY part_count DESC) AS rank
    FROM 
        SupplierDetails
)
SELECT 
    hpc.supplier_name,
    hpc.supplier_address,
    hpc.nation_name,
    hpc.part_count,
    STRING_AGG(p.p_name, ', ') AS part_names
FROM 
    HighestPartCount hpc
JOIN 
    partsupp ps ON hpc.supplier_name = (SELECT s.s_name FROM supplier s WHERE s.s_suppkey = ps.ps_suppkey)
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    hpc.rank <= 10
GROUP BY 
    hpc.supplier_name, hpc.supplier_address, hpc.nation_name, hpc.part_count
ORDER BY 
    hpc.part_count DESC;
