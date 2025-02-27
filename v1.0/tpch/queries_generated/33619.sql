WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        1 AS purchase_level
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'

    UNION ALL

    SELECT 
        co.c_custkey,
        co.c_name,
        co.c_acctbal,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        purchase_level + 1
    FROM 
        CustomerOrders co
    JOIN 
        orders o ON co.o_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate < co.o_orderdate
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.total_cost,
        sp.order_count,
        ROW_NUMBER() OVER (ORDER BY sp.total_cost DESC) AS rn
    FROM 
        SupplierPerformance sp
),
FinalResults AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        MAX(co.o_totalprice) AS max_order_price,
        STRING_AGG(DISTINCT ts.s_name, ', ') AS top_suppliers,
        COUNT(DISTINCT co.o_orderkey) AS orders_count
    FROM 
        CustomerOrders co
    LEFT JOIN 
        TopSuppliers ts ON ts.rn <= 5
    GROUP BY 
        co.c_custkey, co.c_name
)
SELECT 
    fr.c_custkey,
    fr.c_name,
    fr.max_order_price,
    COALESCE(fr.top_suppliers, 'No suppliers') AS top_suppliers,
    fr.orders_count
FROM 
    FinalResults fr
WHERE 
    fr.orders_count > 2
ORDER BY 
    fr.max_order_price DESC;
