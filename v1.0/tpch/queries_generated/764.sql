WITH SupplierPricing AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        sp.p_partkey,
        sp.s_suppkey,
        sp.p_name,
        sp.s_name,
        sp.ps_supplycost
    FROM SupplierPricing sp
    WHERE sp.rn <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    so.p_name,
    so.s_name,
    co.c_name,
    COALESCE(co.total_spent, 0) AS total_spent,
    COALESCE(co.order_count, 0) AS order_count,
    CASE 
        WHEN co.total_spent > 1000 THEN 'High Value Customer'
        WHEN co.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment,
    COUNT(DISTINCT l.o_orderkey) AS total_orders
FROM TopSuppliers so
LEFT JOIN CustomerOrders co ON so.s_suppkey = co.c_custkey
LEFT JOIN orders l ON l.o_custkey = co.c_custkey
WHERE so.ps_supplycost < 100 AND so.ps_availqty > 0
GROUP BY so.p_name, so.s_name, co.c_name, co.total_spent, co.order_count
ORDER BY total_spent DESC;
