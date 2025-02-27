WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        nation.n_name AS nation_name,
        ranked.s_name AS supplier_name,
        ranked.total_available_quantity,
        ranked.total_supply_cost
    FROM 
        RankedSuppliers ranked
    JOIN 
        nation ON ranked.s_nationkey = nation.n_nationkey
    WHERE 
        ranked.rank <= 3
)
SELECT 
    ts.nation_name,
    STRING_AGG(ts.supplier_name, ', ') AS top_suppliers,
    SUM(ts.total_available_quantity) AS total_quantity,
    ROUND(SUM(ts.total_supply_cost), 2) AS total_supply_cost
FROM 
    TopSuppliers ts
GROUP BY 
    ts.nation_name
ORDER BY 
    total_quantity DESC;
