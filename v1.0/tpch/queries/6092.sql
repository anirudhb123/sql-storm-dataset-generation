WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_supply_value DESC
    LIMIT 10
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.c_name,
    r.c_acctbal,
    ts.s_name AS top_supplier_name,
    ts.total_supply_value
FROM 
    RankedOrders r
JOIN 
    TopSuppliers ts ON r.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_suppkey IN (SELECT s_suppkey FROM supplier WHERE s_nationkey = ts.s_suppkey)
    )
WHERE 
    r.rn <= 5
ORDER BY 
    r.o_orderdate DESC, 
    r.o_totalprice DESC;