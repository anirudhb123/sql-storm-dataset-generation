WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey, s.s_suppkey, s.s_name
),

TopSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        ns.n_name AS nation_name, 
        rs.s_name AS supplier_name, 
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.rnk <= 3
),

OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_name AS customer_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name
)

SELECT 
    ts.region_name, 
    ts.nation_name, 
    ts.supplier_name, 
    od.customer_name, 
    od.total_order_value
FROM 
    TopSuppliers ts
JOIN 
    OrderDetails od ON ts.total_supply_cost >= od.total_order_value
ORDER BY 
    ts.region_name, ts.nation_name, ts.supplier_name;
