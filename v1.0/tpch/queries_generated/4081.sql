WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
LineItemSummary AS (
    SELECT 
        l.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.o_orderkey
)
SELECT 
    c.c_name, 
    COALESCE(SUM(ls.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    COALESCE(SUM(CASE WHEN rs.rn = 1 THEN s.s_acctbal END), 0) AS highest_supplier_acctbal
FROM 
    CustomerOrders co
LEFT JOIN 
    LineItemSummary ls ON co.o_orderkey = ls.o_orderkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN part p ON ps.ps_partkey = p.p_partkey
        WHERE p.p_brand = 'Brand#123' AND p.p_size >= 15 
        ORDER BY ps.ps_supplycost DESC
        LIMIT 1
    )
JOIN 
    customer c ON co.c_custkey = c.c_custkey
GROUP BY 
    c.c_name
HAVING 
    total_orders > 5 
ORDER BY 
    total_revenue DESC;
