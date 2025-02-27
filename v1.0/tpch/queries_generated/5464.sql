WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        rs.s_name AS supplier_name, 
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey))
    WHERE 
        rs.rn <= 5
)
SELECT 
    ts.region_name, 
    SUM(o.o_totalprice) AS total_orders_value,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_value,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    TopSuppliers ts
JOIN 
    orders o ON ts.supplier_name = (SELECT s.s_name FROM supplier s WHERE s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)))
JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    ts.region_name
ORDER BY 
    total_orders_value DESC;
