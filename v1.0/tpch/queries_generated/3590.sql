WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(co.total_spent, 0) AS total_spent,
        co.order_count
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        co.total_spent IS NOT NULL OR co.order_count IS NOT NULL
)
SELECT
    p.p_name,
    ps.ps_supplycost,
    ps.ps_availqty,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS total_returned_qty,
    COALESCE(ROUND(AVG(CASE WHEN l.l_linestatus = 'F' THEN l.l_extendedprice * (1 - l.l_discount) END), 2), 0) AS avg_final_price,
    tc.c_name AS top_customer
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rnk = 1
LEFT JOIN 
    TopCustomers tc ON tc.order_count > 5
WHERE 
    ps.ps_availqty > 0
GROUP BY 
    p.p_name, ps.ps_supplycost, ps.ps_availqty, tc.c_name
ORDER BY 
    total_returned_qty DESC, avg_final_price DESC;
