WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS supply_count,
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
QualifiedSuppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.supply_count,
        r.part_names,
        ROW_NUMBER() OVER (ORDER BY r.supply_count DESC) AS rank
    FROM 
        RankedSuppliers r
    WHERE 
        r.supply_count >= 5
)
SELECT 
    c.c_name,
    c.c_address,
    q.s_name,
    q.part_names
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    QualifiedSuppliers q ON l.l_suppkey = q.s_suppkey
WHERE 
    o.o_orderstatus = 'O'
ORDER BY 
    c.c_name, q.s_name;
