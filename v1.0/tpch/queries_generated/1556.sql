WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY AVG(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        n.n_name AS nation_name,
        rs.avg_supplycost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.supplier_rank <= 5
),
OrderTotals AS (
    SELECT 
        co.c_custkey,
        SUM(co.total_order_value) AS total_value
    FROM 
        CustomerOrders co
    WHERE 
        co.o_orderstatus = 'O'
    GROUP BY 
        co.c_custkey
)
SELECT 
    c.c_custkey,
    c.c_name,
    ot.total_value,
    COALESCE(ts.avg_supplycost, 0) AS avg_supplier_cost,
    CASE 
        WHEN ot.total_value IS NULL THEN 'No Orders'
        WHEN ot.total_value > 1000 THEN 'High Value'
        WHEN ot.total_value BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    customer c
LEFT JOIN 
    OrderTotals ot ON c.c_custkey = ot.c_custkey
LEFT JOIN 
    TopSuppliers ts ON ts.s_nationkey = c.c_nationkey
WHERE 
    c.c_acctbal > 0
ORDER BY 
    c.c_custkey;
