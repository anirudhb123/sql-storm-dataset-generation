WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        COUNT(rs.s_suppkey) AS top_supplier_count,
        SUM(rs.total_supply_cost) AS total_region_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        region r ON rs.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    COALESCE(ts.top_supplier_count, 0) AS top_supplier_count,
    COALESCE(ts.total_region_supply_cost, 0) AS total_region_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_order_value
FROM 
    region r
LEFT JOIN 
    TopSuppliers ts ON r.r_name = ts.r_name
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
