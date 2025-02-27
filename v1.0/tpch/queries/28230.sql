WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
AggregateData AS (
    SELECT 
        p.p_type, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_type
),
StringProcessed AS (
    SELECT 
        p.p_name, 
        CONCAT('Part: ', p.p_name, ' | Type: ', p.p_type, ' | Retail Price: $', ROUND(p.p_retailprice, 2)) AS part_description
    FROM 
        part p
)
SELECT 
    a.p_type, 
    a.supplier_count, 
    a.avg_acctbal, 
    MAX(sp.part_description) AS example_description
FROM 
    AggregateData a
JOIN 
    StringProcessed sp ON a.p_type = sp.p_name
WHERE 
    EXISTS (
        SELECT 1 
        FROM RankedSuppliers r 
        WHERE r.rank <= 5 AND r.s_suppkey IN (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_type = a.p_type))
    )
GROUP BY 
    a.p_type, a.supplier_count, a.avg_acctbal
ORDER BY 
    a.avg_acctbal DESC;
