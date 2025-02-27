WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
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
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.total_spent,
        ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) as customer_rank
    FROM 
        CustomerOrders c
    WHERE 
        c.total_spent > (
            SELECT 
                AVG(total_spent) 
            FROM 
                CustomerOrders
        )
)
SELECT 
    hvc.c_custkey,
    hvc.total_spent,
    p.p_partkey,
    p.p_name,
    rank_sup.s_name AS top_supplier,
    rank_sup.s_acctbal AS top_supplier_balance
FROM 
    HighValueCustomers hvc
JOIN 
    lineitem li ON li.l_orderkey IN (
        SELECT 
            o.o_orderkey
        FROM 
            orders o
        WHERE 
            o.o_custkey = hvc.c_custkey
    )
JOIN 
    part p ON li.l_partkey = p.p_partkey
LEFT JOIN 
    RankedSuppliers rank_sup ON rank_sup.s_suppkey = li.l_suppkey 
WHERE 
    rank_sup.supplier_rank = 1
ORDER BY 
    hvc.total_spent DESC, 
    p.p_name ASC

