WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
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
        r.r_name AS region_name,
        rs.s_name AS supplier_name,
        rs.total_availqty,
        rs.total_supplycost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
)
SELECT 
    fs.region_name,
    fs.supplier_name,
    fs.total_availqty,
    fs.total_supplycost,
    ROUND(fs.total_supplycost / NULLIF(fs.total_availqty, 0), 2) AS avg_supplycost_per_qty
FROM 
    FilteredSuppliers fs
ORDER BY 
    fs.region_name, fs.total_supplycost DESC;
