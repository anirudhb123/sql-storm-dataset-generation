
WITH StringAggregates AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        c.c_name,
        o.o_orderkey,
        STRING_AGG(DISTINCT CONCAT(p.p_name, ' ', s.s_name), '; ') AS part_supplier_names,
        COUNT(DISTINCT c.c_custkey) AS distinct_customers,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        p.p_name LIKE 'S%' 
        AND s.s_name IS NOT NULL 
        AND c.c_name IS NOT NULL
    GROUP BY 
        p.p_partkey, p.p_name, s.s_name, c.c_name, o.o_orderkey
),
Result AS (
    SELECT 
        p_partkey,
        p_name,
        part_supplier_names,
        distinct_customers,
        total_quantity,
        LENGTH(part_supplier_names) AS supplier_names_length,
        CHAR_LENGTH(part_supplier_names) AS supplier_names_char_length
    FROM 
        StringAggregates
)
SELECT 
    *
FROM 
    Result
ORDER BY 
    total_quantity DESC, supplier_names_length DESC;
