
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        s.s_name AS supplier_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
AggregatedData AS (
    SELECT 
        p_type,
        COUNT(*) AS part_count,
        AVG(ps_supplycost) AS avg_supplycost,
        LISTAGG(supplier_name, ', ') AS suppliers
    FROM 
        RankedParts
    WHERE 
        rank <= 5
    GROUP BY 
        p_type
)
SELECT 
    p_type,
    part_count,
    avg_supplycost,
    suppliers
FROM 
    AggregatedData
WHERE 
    part_count > 10
ORDER BY 
    avg_supplycost DESC;
