
WITH part_supplier_info AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        s.s_name, 
        s.s_nationkey, 
        ps.ps_supplycost, 
        ps.ps_availqty, 
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
top_suppliers AS (
    SELECT 
        p_partkey, 
        p_name, 
        p_brand, 
        s_name, 
        ps_supplycost, 
        ps_availqty
    FROM 
        part_supplier_info
    WHERE 
        rn <= 3
)
SELECT 
    t.p_partkey,
    t.p_name,
    t.p_brand,
    LISTAGG(t.s_name, ', ') AS supplier_names,
    AVG(t.ps_supplycost) AS avg_supplycost,
    SUM(t.ps_availqty) AS total_available_qty
FROM 
    top_suppliers t
GROUP BY 
    t.p_partkey, t.p_name, t.p_brand
ORDER BY 
    avg_supplycost DESC;
