WITH SupplierTotalCost AS (
    SELECT 
        ps.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.s_suppkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        stc.total_cost
    FROM 
        supplier s
    JOIN 
        SupplierTotalCost stc ON s.s_suppkey = stc.s_suppkey
    WHERE 
        stc.total_cost > (
            SELECT 
                AVG(total_cost) 
            FROM 
                SupplierTotalCost
        )
),
TopCustomerOrders AS (
    SELECT 
        cus.c_custkey,
        cus.c_name,
        cus.c_acctbal,
        cos.order_count,
        cos.total_spent,
        ROW_NUMBER() OVER (ORDER BY cos.total_spent DESC) as rank
    FROM 
        customer cus
    JOIN 
        CustomerOrderStats cos ON cus.c_custkey = cos.c_custkey
    WHERE 
        cus.c_acctbal IS NOT NULL
)
SELECT 
    tco.c_name AS customer_name,
    tco.order_count,
    tco.total_spent,
    CASE 
        WHEN tco.rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category,
    hs.s_name AS supplier_name,
    hs.total_cost AS supplier_total_cost
FROM 
    TopCustomerOrders tco
LEFT JOIN 
    HighValueSuppliers hs ON hs.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tco.c_custkey)
        GROUP BY ps.ps_suppkey 
        ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC 
        LIMIT 1
    )
WHERE 
    tco.total_spent > 1000
ORDER BY 
    tco.total_spent DESC;
