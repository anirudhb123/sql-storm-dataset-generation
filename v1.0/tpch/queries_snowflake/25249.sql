
WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        LENGTH(s.s_comment) > 15
), FilteredSuppliers AS (
    SELECT 
        s_name,
        s_acctbal,
        nation_name
    FROM 
        RankedSuppliers
    WHERE 
        rank <= 5
), SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        FilteredSuppliers fs ON ps.ps_suppkey = (SELECT s.s_suppkey FROM supplier s WHERE s.s_name = fs.s_name)
), StringMetrics AS (
    SELECT 
        p_name,
        p_brand,
        p_type,
        p_container,
        SUM(ps_availqty) AS total_avail_qty,
        AVG(ps_supplycost) AS avg_supply_cost,
        LISTAGG(CONCAT(p_name, ' - ', p_brand, ' [', p_type, ']'), '; ') WITHIN GROUP (ORDER BY p_name) AS detailed_info
    FROM 
        SupplierParts
    GROUP BY 
        p_name, p_brand, p_type, p_container
)
SELECT 
    *,
    (SELECT COUNT(*) FROM FilteredSuppliers) AS total_suppliers
FROM 
    StringMetrics
WHERE 
    LENGTH(detailed_info) > 50
ORDER BY 
    total_avail_qty DESC;
