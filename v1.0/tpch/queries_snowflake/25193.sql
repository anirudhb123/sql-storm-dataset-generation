
WITH RankedSuppliers AS (
    SELECT 
        s.s_name AS supplier_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_name, r.r_name, r.r_regionkey
),
FilteredSuppliers AS (
    SELECT 
        supplier_name,
        region_name,
        total_cost
    FROM 
        RankedSuppliers
    WHERE 
        rank <= 3
)
SELECT 
    f.supplier_name,
    f.region_name,
    f.total_cost,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice) AS avg_extended_price,
    LISTAGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    FilteredSuppliers f
LEFT JOIN 
    supplier s ON f.supplier_name = s.s_name
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    f.supplier_name, f.region_name, f.total_cost
ORDER BY 
    f.total_cost DESC;
