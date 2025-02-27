WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
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
        s.s_name,
        s.total_cost
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.supplier_rank <= 5
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierOrderSummary AS (
    SELECT 
        ts.r_name,
        ts.s_name,
        SUM(hv.order_value) AS total_order_value
    FROM 
        TopSuppliers ts
    LEFT JOIN 
        HighValueOrders hv ON ts.s_name = hv.o_orderkey
    GROUP BY 
        ts.r_name, ts.s_name
)
SELECT 
    sos.r_name,
    sos.s_name,
    COALESCE(sos.total_order_value, 0) AS total_order_value,
    CASE 
        WHEN sos.total_order_value > 0 THEN 'High Value'
        ELSE 'No Orders'
    END AS order_status
FROM 
    SupplierOrderSummary sos
ORDER BY 
    sos.r_name, sos.s_name;
