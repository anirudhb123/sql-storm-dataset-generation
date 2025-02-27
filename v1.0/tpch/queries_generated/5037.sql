WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name,
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
        rs.rank <= 5
),
DetailedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        l.l_shipmode
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, l.l_shipmode
)
SELECT 
    ts.r_name,
    ts.nation_name,
    ts.supplier_name,
    SUM(do.total_order_value) AS total_order_value,
    COUNT(do.o_orderkey) AS total_orders,
    AVG(do.total_order_value) AS avg_order_value
FROM 
    TopSuppliers ts
JOIN 
    DetailedOrders do ON ts.supplier_name = do.l_shipmode
GROUP BY 
    ts.r_name, ts.nation_name, ts.supplier_name
ORDER BY 
    SUM(do.total_order_value) DESC
LIMIT 10;
