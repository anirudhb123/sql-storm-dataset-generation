WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), FilteredSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        rs.s_name AS supplier_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON n.n_nationkey = (SELECT n_nationkey FROM nation ORDER BY RANDOM() LIMIT 1)
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
)
SELECT 
    COUNT(*) AS supplier_count,
    AVG(total_supply_cost) AS avg_supply_cost
FROM 
    FilteredSuppliers
WHERE 
    total_supply_cost > (SELECT AVG(total_supply_cost) FROM FilteredSuppliers);
