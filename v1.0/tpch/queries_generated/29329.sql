WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name, 
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        SUM(COALESCE(ps.ps_availqty, 0)) AS total_available_quantity 
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container
)
SELECT 
    fp.p_name, 
    fp.total_available_quantity, 
    rs.s_name AS supplier_name, 
    rs.nation_name 
FROM 
    FilteredParts fp 
JOIN 
    RankedSuppliers rs ON fp.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey = rs.s_suppkey
    ) 
WHERE 
    rs.rank <= 3 
ORDER BY 
    fp.total_available_quantity DESC, rs.nation_name, rs.s_name;
