WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_supply_value
    FROM 
        RankedSuppliers s
    WHERE 
        s.rank <= 10
),
CustomerOrderTotals AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
)
SELECT 
    cs.c_name, 
    cs.total_spent,
    ts.s_name AS top_supplier,
    od.o_orderdate,
    SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_order_value
FROM 
    CustomerOrderTotals cs
JOIN 
    OrderDetails od ON cs.c_custkey = od.o_orderkey
JOIN 
    TopSuppliers ts ON od.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
GROUP BY 
    cs.c_name, 
    cs.total_spent, 
    ts.s_name, 
    od.o_orderdate
ORDER BY 
    total_order_value DESC;
