WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        (s.s_acctbal > 5000 OR s.s_name LIKE 'A%')
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
HighCostSuppliers AS (
    SELECT 
        r.r_name AS region,
        COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
        AVG(rs.total_supply_cost) AS avg_supply_cost
    FROM 
        region r
    JOIN 
        RankedSuppliers rs ON r.r_regionkey = rs.nation
    WHERE 
        rs.rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    region,
    supplier_count,
    avg_supply_cost 
FROM 
    HighCostSuppliers
ORDER BY 
    avg_supply_cost DESC;
