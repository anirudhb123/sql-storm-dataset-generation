WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.total_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.supplier_rank <= 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        co.c_custkey, 
        co.c_name, 
        co.total_order_value
    FROM 
        CustomerOrders co
    WHERE 
        co.total_order_value > 10000
),
FinalResults AS (
    SELECT 
        hvc.c_custkey, 
        hvc.c_name, 
        ts.s_suppkey, 
        ts.s_name AS supplier_name, 
        ts.total_cost
    FROM 
        HighValueCustomers hvc
    JOIN 
        lineitem li ON li.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = hvc.c_custkey)
    JOIN 
        partsupp ps ON li.l_partkey = ps.ps_partkey
    JOIN 
        TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
)
SELECT 
    fr.c_custkey, 
    fr.c_name, 
    fr.s_suppkey, 
    fr.supplier_name, 
    fr.total_cost
FROM 
    FinalResults fr
ORDER BY 
    fr.total_cost DESC;
