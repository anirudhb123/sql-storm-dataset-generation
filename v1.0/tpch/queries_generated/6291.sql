WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_available_qty,
        ss.total_value,
        ROW_NUMBER() OVER (ORDER BY ss.total_value DESC) AS rank
    FROM 
        SupplierStats ss
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_available_qty,
    ts.total_value,
    os.total_order_value
FROM 
    TopSuppliers ts
LEFT JOIN 
    (
        SELECT 
            os.o_orderkey,
            os.total_order_value
        FROM 
            OrderSummary os
    ) os ON ts.rank = (SELECT COUNT(*) FROM TopSuppliers ts2 WHERE ts2.total_value > ts.total_value) + 1
WHERE 
    ts.rank <= 10
ORDER BY 
    ts.total_value DESC;
