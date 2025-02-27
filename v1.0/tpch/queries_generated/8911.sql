WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    WHERE 
        rs.rank <= 5
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        c.c_name AS customer_name, 
        c.c_acctbal
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > 1000
)
SELECT 
    hvo.o_orderkey, 
    hvo.customer_name, 
    hvo.o_totalprice, 
    ts.s_name AS top_supplier, 
    ts.total_supply_cost
FROM 
    HighValueOrders hvo
LEFT JOIN 
    lineitem l ON hvo.o_orderkey = l.l_orderkey
LEFT JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    hvo.o_totalprice > 1000
ORDER BY 
    hvo.o_totalprice DESC, 
    ts.total_supply_cost DESC;
