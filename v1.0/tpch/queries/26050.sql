WITH SupplierDetails AS (
    SELECT 
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name, s.s_address, n.n_name, r.r_name
),

TopSuppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_supply_cost DESC) AS rank
    FROM 
        SupplierDetails
)

SELECT 
    rank,
    s_name,
    s_address,
    nation_name,
    region_name,
    part_count,
    total_supply_cost,
    part_names
FROM 
    TopSuppliers
WHERE 
    rank <= 10
ORDER BY 
    rank;
