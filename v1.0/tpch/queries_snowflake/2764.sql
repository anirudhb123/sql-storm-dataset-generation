
WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.n_name AS nation_name,
    COUNT(DISTINCT fo.o_orderkey) AS completed_orders,
    SUM(fo.total_order_value) AS total_order_value,
    LISTAGG(DISTINCT rs.s_name, ', ') AS top_suppliers
FROM 
    nation r
LEFT JOIN 
    RankedSuppliers rs ON r.n_nationkey = rs.s_nationkey AND rs.rn <= 3
LEFT JOIN 
    FilteredOrders fo ON rs.s_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = fo.o_orderkey) 
GROUP BY 
    r.n_name
HAVING 
    SUM(fo.total_order_value) > (SELECT AVG(total_order_value) FROM FilteredOrders)
ORDER BY 
    total_order_value DESC;
