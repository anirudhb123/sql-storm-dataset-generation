WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
)
SELECT 
    ts.region_name,
    ts.nation_name,
    SUM(o.o_totalprice) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_value,
    COUNT(o.o_orderkey) AS total_order_count
FROM 
    TopSuppliers ts
JOIN 
    orders o ON ts.supplier_name = o.o_clerk -- Assuming o_clerk as a representation of supplier (for demonstration)
GROUP BY 
    ts.region_name, ts.nation_name
ORDER BY 
    total_orders DESC, avg_order_value DESC;
