WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
OrderSummary AS (
    SELECT 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        c.c_name
)
SELECT 
    p.p_name,
    COALESCE(RS.s_name, 'No Supplier') AS supplier_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    OS.total_spent,
    (OS.total_orders * 1.0 / NULLIF(NULLIF(OS.total_spent, 0), 0)) AS avg_order_value
FROM 
    lineitem li
LEFT JOIN 
    part p ON li.l_partkey = p.p_partkey
LEFT JOIN 
    RankedSuppliers RS ON RS.s_suppkey = li.l_suppkey AND RS.rnk = 1
LEFT JOIN 
    OrderSummary OS ON OS.total_orders > 0 
GROUP BY 
    p.p_name, supplier_name, OS.total_spent
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
