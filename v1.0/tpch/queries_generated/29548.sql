WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name, 
        n.n_name AS nation_name,
        p.p_name AS part_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
AggregatedData AS (
    SELECT 
        nation_name,
        COUNT(DISTINCT s_suppkey) AS supplier_count,
        SUM(ps_supplycost) AS total_supplycost
    FROM 
        RankedSuppliers
    WHERE 
        rank <= 5
    GROUP BY 
        nation_name
)
SELECT 
    nation_name,
    supplier_count,
    total_supplycost,
    CONCAT('The top 5 suppliers contribute to a total supply cost of $', 
           FORMAT(total_supplycost, 2), 
           ' from ', 
           supplier_count, 
           ' suppliers in ', 
           nation_name) AS summary
FROM 
    AggregatedData
ORDER BY 
    total_supplycost DESC;
