WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sc.total_supply_cost,
        sc.total_available_qty,
        RANK() OVER (ORDER BY sc.total_supply_cost DESC) AS rank
    FROM 
        SupplierCosts sc
    JOIN 
        supplier s ON sc.s_suppkey = s.s_suppkey
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_supply_cost,
    ts.total_available_qty
FROM 
    TopSuppliers ts
WHERE 
    ts.rank <= 10
ORDER BY 
    ts.total_supply_cost DESC;

-- Additional benchmarking by joining with orders and calculating average order price
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_supply_cost,
    ts.total_available_qty,
    AVG(o.o_totalprice) AS avg_order_price
FROM 
    TopSuppliers ts
JOIN 
    lineitem l ON l.l_suppkey = ts.s_suppkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
GROUP BY 
    ts.s_suppkey, ts.s_name, ts.total_supply_cost, ts.total_available_qty
ORDER BY 
    avg_order_price DESC;
