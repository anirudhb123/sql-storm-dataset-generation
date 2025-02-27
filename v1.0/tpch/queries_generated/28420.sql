WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(ps.ps_partkey) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        t.s_name AS supplier_name,
        t.total_parts,
        t.total_quantity
    FROM 
        RankedSuppliers t
    JOIN 
        nation n ON t.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        t.rank <= 3
)
SELECT 
    region_name,
    supplier_name,
    total_parts,
    total_quantity,
    CONCAT('Supplier: ', supplier_name, ' from ', region_name, ' has parts: ', CAST(total_parts AS VARCHAR), ' with total quantity: ', CAST(total_quantity AS VARCHAR)) AS supplier_info
FROM 
    TopSuppliers
ORDER BY 
    region_name, total_quantity DESC;
