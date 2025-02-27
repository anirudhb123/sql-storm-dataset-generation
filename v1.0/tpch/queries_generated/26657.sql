WITH supplier_details AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        n.n_name, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        LENGTH(s.s_name) > 5 
        AND n.n_name LIKE '%land%'
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),
total_values AS (
    SELECT 
        sd.s_suppkey, 
        sd.s_name, 
        sd.n_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost 
    FROM 
        supplier_details sd
    JOIN 
        partsupp ps ON sd.s_suppkey = ps.ps_suppkey
    GROUP BY 
        sd.s_suppkey, sd.s_name, sd.n_name
)
SELECT 
    tv.s_suppkey, 
    tv.s_name,
    tv.n_name,
    tv.total_supplycost,
    sd.part_count,
    sd.part_names
FROM 
    total_values tv
JOIN 
    supplier_details sd ON tv.s_suppkey = sd.s_suppkey
ORDER BY 
    tv.total_supplycost DESC
LIMIT 10;
