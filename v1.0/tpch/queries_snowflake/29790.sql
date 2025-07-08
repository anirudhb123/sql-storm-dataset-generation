
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        LISTAGG(DISTINCT s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS suppliers_list,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY COUNT(DISTINCT ps.ps_suppkey) DESC) AS brand_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.supplier_count,
        rp.total_available_quantity,
        rp.suppliers_list
    FROM 
        RankedParts rp
    WHERE 
        rp.brand_rank <= 3
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_brand,
    fp.supplier_count,
    fp.total_available_quantity,
    fp.suppliers_list,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    SUM(o.o_totalprice) AS total_sales_value,
    LISTAGG(DISTINCT c.c_name, ', ') WITHIN GROUP (ORDER BY c.c_name) AS customer_names
FROM 
    FilteredParts fp
LEFT JOIN 
    lineitem l ON fp.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    fp.p_partkey, fp.p_name, fp.p_brand, fp.supplier_count, fp.total_available_quantity, fp.suppliers_list
ORDER BY 
    fp.total_available_quantity DESC;
