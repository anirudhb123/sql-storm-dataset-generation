WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
), HighCostSuppliers AS (
    SELECT 
        r.r_name AS region,
        COUNT(*) AS num_high_cost_suppliers
    FROM 
        RankedSuppliers rs
    JOIN 
        region r ON rs.nation = (
            SELECT n.n_name
            FROM nation n
            WHERE n.n_regionkey = r.r_regionkey
            LIMIT 1
        )
    WHERE 
        rs.total_supply_cost > (SELECT AVG(total_supply_cost) FROM RankedSuppliers)
    GROUP BY 
        r.r_name
)
SELECT 
    hcs.region,
    hcs.num_high_cost_suppliers,
    SUM(o.o_totalprice) AS total_order_value
FROM 
    HighCostSuppliers hcs
JOIN 
    orders o ON hcs.num_high_cost_suppliers > 0
GROUP BY 
    hcs.region, hcs.num_high_cost_suppliers
ORDER BY 
    hcs.region;
