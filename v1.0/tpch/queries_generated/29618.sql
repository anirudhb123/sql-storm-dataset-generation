WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_address,
        s.s_phone,
        CAST(s.s_acctbal AS DECIMAL(12,2)) AS balance,
        part_count,
        part_names,
        RANK() OVER (ORDER BY part_count DESC) AS rank
    FROM 
        RankedSuppliers s
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.s_address,
    t.s_phone,
    t.balance,
    t.part_count,
    t.part_names
FROM 
    TopSuppliers t
WHERE 
    t.rank <= 10
ORDER BY 
    t.rank;
