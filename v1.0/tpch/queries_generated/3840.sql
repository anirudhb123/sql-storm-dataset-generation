WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        s.s_name,
        s.s_acctbal
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        RankedSuppliers s ON n.n_nationkey = s.s_nationkey
    WHERE 
        s.rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineprice
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    t.r_name AS region_name,
    t.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.line_items,
    o.total_lineprice,
    co.total_orders,
    co.total_spent,
    COALESCE((o.total_lineprice / NULLIF(co.total_spent, 0)), 0) AS spending_ratio
FROM 
    TopSuppliers t
LEFT JOIN 
    CustomerOrders co ON t.s_name = co.c_name 
LEFT JOIN 
    OrderDetails o ON o.o_orderkey = co.c_custkey
WHERE 
    o.line_items > 0 
    AND co.total_orders IS NOT NULL
ORDER BY 
    t.r_name, spending_ratio DESC;
