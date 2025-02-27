WITH PartStatistics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        COUNT(ps.ps_supplycost) AS supply_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(CASE WHEN ps.ps_availqty > 0 THEN 1 ELSE 0 END) AS available_suppliers
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        COUNT(ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
    ORDER BY 
        total_supply_cost DESC
    LIMIT 10
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.name_length,
    ps.supply_count,
    ps.avg_supply_cost,
    ps.available_suppliers,
    ts.s_name,
    ts.n_name,
    ts.parts_supplied,
    ts.total_supply_cost
FROM 
    PartStatistics ps
JOIN 
    TopSuppliers ts ON ps.p_partkey IN (
        SELECT 
            ps_partkey 
        FROM 
            partsupp 
        WHERE 
            ps_suppkey = ts.s_suppkey
    )
ORDER BY 
    ps.available_suppliers DESC, ps.avg_supply_cost DESC;
