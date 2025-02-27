WITH StringAggregation AS (
    SELECT 
        n.n_name AS nation_name,
        STRING_AGG(DISTINCT CONCAT(s.s_name, ' - ', p.p_name), '; ') AS supplier_parts
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE LENGTH(p.p_name) > 20
    GROUP BY n.n_name
),
FilteredResults AS (
    SELECT 
        nation_name,
        supplier_parts,
        LENGTH(supplier_parts) AS parts_length
    FROM StringAggregation
    WHERE parts_length > 100
)
SELECT 
    nation_name,
    UPPER(supplier_parts) AS upper_supplier_parts,
    REPLACE(supplier_parts, ';', ', ') AS comma_separated_parts
FROM FilteredResults
ORDER BY nation_name;
