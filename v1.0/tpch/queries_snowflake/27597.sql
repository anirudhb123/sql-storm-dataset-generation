
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.s_acctbal AS supplier_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
)
SELECT 
    region_name,
    nation_name,
    LISTAGG(supplier_name || ' (Balance: ' || supplier_acctbal || ')', ', ') WITHIN GROUP (ORDER BY supplier_name) AS top_suppliers
FROM 
    FilteredSuppliers
GROUP BY 
    region_name, nation_name
ORDER BY 
    region_name, nation_name;
