WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(s.s_acctbal) AS average_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_available_qty,
        ss.average_acctbal,
        RANK() OVER (ORDER BY ss.total_available_qty DESC) AS rank
    FROM 
        SupplierSummary ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_available_qty > 0
)
SELECT 
    c.c_name,
    c.c_acctbal,
    t.s_name AS supplier_name,
    o.total_revenue,
    o.line_item_count,
    CASE 
        WHEN o.total_revenue > 10000 THEN 'High Value'
        WHEN o.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS revenue_category
FROM 
    customer c
LEFT JOIN 
    OrderSummary o ON c.c_custkey = o.o_custkey
JOIN 
    TopSuppliers t ON o.o_orderkey = (SELECT MIN(o1.o_orderkey) FROM OrderSummary o1 WHERE o1.total_revenue = o.total_revenue AND o1.o_custkey = o.o_custkey)
WHERE 
    c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
ORDER BY 
    c.c_acctbal DESC, o.total_revenue DESC;
