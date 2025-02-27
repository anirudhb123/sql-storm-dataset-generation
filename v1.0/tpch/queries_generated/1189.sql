WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost) AS total_supplycost,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS num_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name
    FROM 
        SupplierStats s
    WHERE 
        s.total_availqty > (
            SELECT 
                AVG(total_availqty) 
            FROM 
                SupplierStats
        )
),
OrderPriorities AS (
    SELECT 
        o.o_orderpriority,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        orders o
    GROUP BY 
        o.o_orderpriority
),
TopCustomers AS (
    SELECT 
        c.customer_name, 
        c.total_spent,
        RANK() OVER (ORDER BY c.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders c
)
SELECT 
    sc.s_name AS supplier_name,
    tc.customer_name,
    tc.total_spent,
    op.total_order_value,
    CASE 
        WHEN tc.num_orders IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    CASE 
        WHEN sc.total_supplycost IS NULL THEN 'Cost Unknown'
        ELSE CAST(sc.total_supplycost AS VARCHAR)
    END AS supplier_cost
FROM 
    HighValueSuppliers sc
FULL OUTER JOIN 
    TopCustomers tc ON sc.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_size > 10
        )
        LIMIT 1
    )
LEFT JOIN 
    OrderPriorities op ON tc.customer_name IS NOT NULL
WHERE 
    (sc.total_supplycost IS NOT NULL OR tc.total_spent > 10000)
ORDER BY 
    sc.s_name, tc.total_spent DESC;
