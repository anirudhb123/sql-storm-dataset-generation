WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
StringsProcessed AS (
    SELECT 
        p.p_name,
        CONCAT('Supplier: ', rs.s_name, ' | Nation: ', rs.nation_name, ' | Price: ', 
               FORMAT(ps.ps_supplycost, 2), ' | Comment: ', p.p_comment) AS processed_string
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    WHERE 
        rs.rank <= 3
)
SELECT 
    processed_string
FROM 
    StringsProcessed
ORDER BY 
    p_name;
