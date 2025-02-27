WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) as rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
AggregatedData AS (
    SELECT 
        p.p_type,
        COUNT(DISTINCT s.s_name) AS num_suppliers,
        SUM(ps.ps_supplycost) AS total_supplycost,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        RankedSuppliers s 
    JOIN 
        part p ON s.p_name = p.p_name
    WHERE 
        s.rnk = 1
    GROUP BY 
        p.p_type
)
SELECT 
    a.p_type,
    a.num_suppliers,
    a.total_supplycost,
    a.avg_supplycost,
    RANK() OVER (ORDER BY a.avg_supplycost DESC) AS supplycost_rank
FROM 
    AggregatedData a
WHERE 
    a.num_suppliers > 5
ORDER BY 
    a.avg_supplycost DESC;
