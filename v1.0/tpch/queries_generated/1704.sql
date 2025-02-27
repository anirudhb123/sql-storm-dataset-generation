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
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
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
        c.c_name,
        c.c_acctbal,
        cos.total_orders,
        cos.total_spent,
        cos.avg_order_value
    FROM 
        CustomerOrderSummary cos
    JOIN 
        customer c ON cos.c_custkey = c.c_custkey
    WHERE 
        cos.total_spent > 100000
)
SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    COALESCE(rv.total_orders, 0) AS total_orders,
    rv.total_spent,
    hv.c_name AS high_value_customer,
    hv.avg_order_value
FROM 
    part p
LEFT JOIN 
    RankedSuppliers s ON s.p_partkey = p.p_partkey AND s.rnk = 1
LEFT JOIN 
    CustomerOrderSummary rv ON rv.total_orders > 0
LEFT JOIN 
    HighValueCustomers hv ON hv.c_custkey = rv.c_custkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    p.p_name, hv.avg_order_value DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
