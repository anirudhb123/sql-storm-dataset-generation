
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
        rs.part_count,
        rs.part_names,
        RANK() OVER (ORDER BY rs.part_count DESC) AS rank
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON s.s_suppkey = rs.s_suppkey
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
