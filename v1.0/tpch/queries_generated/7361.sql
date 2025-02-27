WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        COUNT(ps.ps_availqty) AS supply_count,
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
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        l.l_quantity,
        l.l_extendedprice,
        s.s_name AS supplier_name
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT 
    od.supplier_name,
    SUM(od.l_extendedprice) AS total_revenue,
    SUM(od.l_quantity) AS total_quantity,
    COUNT(DISTINCT od.o_orderkey) AS total_orders
FROM 
    OrderDetails od
GROUP BY 
    od.supplier_name
ORDER BY 
    total_revenue DESC
LIMIT 5;
