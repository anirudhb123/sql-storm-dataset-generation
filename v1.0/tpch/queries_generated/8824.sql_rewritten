WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
), TotalOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey
), TopOrders AS (
    SELECT 
        o.o_orderkey, 
        o.total_order_value,
        RANK() OVER (ORDER BY o.total_order_value DESC) AS order_rank
    FROM 
        TotalOrders o
)
SELECT 
    ts.o_orderkey, 
    ts.total_order_value,
    rs.s_name AS top_supplier,
    rs.total_supply_cost
FROM 
    TopOrders ts
JOIN 
    RankedSuppliers rs ON ts.o_orderkey = (
        SELECT 
            l.l_orderkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_orderkey = ts.o_orderkey 
        ORDER BY 
            l.l_extendedprice DESC 
        LIMIT 1
    )
WHERE 
    ts.order_rank <= 10;