WITH CustomerOrderSummary AS (
    SELECT 
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_name,
        cos.total_orders,
        cos.total_spent,
        cos.avg_order_value
    FROM 
        CustomerOrderSummary cos
    JOIN 
        customer c ON cos.c_name = c.c_name
    WHERE 
        cos.spending_rank <= 10
),
PartSupplierInfo AS (
    SELECT 
        p.p_name,
        ps.ps_partkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS cost_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    tc.c_name AS customer_name,
    tc.total_orders,
    tc.total_spent,
    p.p_name AS part_name,
    psi.s_name AS supplier_name,
    psi.ps_availqty AS available_quantity,
    psi.ps_supplycost AS supplier_cost
FROM 
    TopCustomers tc
JOIN 
    lineitem l ON l.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        JOIN customer c ON o.o_custkey = c.c_custkey 
        WHERE c.c_name = tc.c_name
    )
JOIN 
    part p ON l.l_partkey = p.p_partkey
JOIN 
    PartSupplierInfo psi ON l.l_partkey = psi.ps_partkey AND psi.cost_rank = 1
WHERE 
    l.l_discount > 0.05
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    tc.total_spent DESC, p.p_name ASC;
