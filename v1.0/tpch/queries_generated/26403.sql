WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_name ILIKE '%widget%'
),
suppliers_with_parts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        ranked_parts p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    s.supplier_name,
    p.part_name,
    SUM(ps.ps_availqty) AS total_available,
    AVG(ps.ps_supplycost) AS average_cost,
    COUNT(DISTINCT CASE WHEN s.s_name IS NOT NULL THEN s.s_suppkey END) AS distinct_suppliers
FROM 
    suppliers_with_parts s
GROUP BY 
    s.supplier_name, p.part_name
ORDER BY 
    average_cost ASC, total_available DESC
LIMIT 100;
