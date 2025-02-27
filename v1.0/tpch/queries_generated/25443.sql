WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
SupplierComments AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        rs.s_name,
        rs.total_supply_value,
        REPLACE(SUBSTRING(s.s_comment, 1, 45), ' ', '-') AS short_comment
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
)
SELECT 
    region, 
    nation, 
    s_name,
    total_supply_value,
    LENGTH(short_comment) AS comment_length
FROM 
    SupplierComments
ORDER BY 
    region, 
    total_supply_value DESC;
