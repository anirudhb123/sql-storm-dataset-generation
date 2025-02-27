WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation
    FROM 
        RankedSuppliers s
    WHERE 
        s.rank <= 3
)
SELECT 
    fs.s_suppkey,
    fs.s_name,
    fs.s_address,
    fs.nation,
    COUNT(DISTINCT ps.ps_partkey) AS part_count,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_type, ')'), ', ') AS part_names 
FROM 
    FilteredSuppliers fs
JOIN 
    partsupp ps ON fs.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    fs.s_suppkey, fs.s_name, fs.s_address, fs.nation
ORDER BY 
    fs.nation, part_count DESC;
