WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), TotalValues AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        SUM(rs.total_supply_value) AS region_supply_value
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.nation_name
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    tv.r_name AS region,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    MAX(tv.region_supply_value) AS max_supply_value,
    MIN(tv.region_supply_value) AS min_supply_value,
    AVG(tv.region_supply_value) AS avg_supply_value
FROM 
    TotalValues tv
JOIN 
    RankedSuppliers rs ON tv.region_supply_value = rs.total_supply_value
GROUP BY 
    tv.r_name
ORDER BY 
    avg_supply_value DESC;
