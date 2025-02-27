
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        supplier_nation,
        s_suppkey,
        s_name,
        total_supplycost
    FROM 
        RankedSuppliers
    WHERE 
        rank <= 3
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cu.c_name AS customer_name,
    cu.total_order_value,
    ts.s_name AS supplier_name,
    ts.total_supplycost
FROM 
    CustomerOrderSummary cu
JOIN 
    TopSuppliers ts ON cu.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = ts.supplier_nation) LIMIT 1)
ORDER BY 
    cu.total_order_value DESC, ts.total_supplycost DESC;
