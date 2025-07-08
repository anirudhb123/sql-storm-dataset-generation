
WITH RankedProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_qty,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost) DESC) AS brand_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
TopProducts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_type,
        rp.supplier_count,
        rp.total_available_qty
    FROM 
        RankedProducts rp
    WHERE 
        rp.brand_rank <= 3
)
SELECT 
    tp.p_brand,
    LISTAGG(tp.p_name, ', ') WITHIN GROUP (ORDER BY tp.p_name) AS product_names,
    SUM(tp.total_available_qty) AS total_qty,
    COUNT(DISTINCT tp.supplier_count) AS unique_suppliers
FROM 
    TopProducts tp
GROUP BY 
    tp.p_brand
ORDER BY 
    total_qty DESC;
