
WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        SUBSTRING(p.p_name, 1, 10) AS short_name,
        CONCAT('Supplier: ', s.s_name, ' - Part: ', p.p_name) AS display_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
NationSupplierDetails AS (
    SELECT 
        n.n_name,
        n.n_regionkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        LISTAGG(DISTINCT s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS supplier_names
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name, n.n_regionkey
),
FinalOutput AS (
    SELECT 
        spd.short_name,
        spd.display_info,
        nsd.n_name AS nation_name,
        nsd.supplier_count,
        nsd.supplier_names,
        SUM(spd.p_retailprice) OVER (PARTITION BY nsd.n_name) AS total_retail_price
    FROM 
        SupplierPartDetails spd
    JOIN 
        NationSupplierDetails nsd ON spd.s_nationkey = nsd.n_regionkey
)
SELECT 
    nation_name,
    COUNT(short_name) AS part_count,
    MIN(total_retail_price) AS min_retail_price,
    MAX(total_retail_price) AS max_retail_price,
    LISTAGG(display_info, '; ') WITHIN GROUP (ORDER BY display_info) AS all_part_info
FROM 
    FinalOutput
GROUP BY 
    nation_name
ORDER BY 
    nation_name;
