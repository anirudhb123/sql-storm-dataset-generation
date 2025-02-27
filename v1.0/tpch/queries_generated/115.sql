WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
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
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        co.total_orders,
        co.total_spent,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_spent > 1000
)
SELECT 
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    ss.unique_parts,
    hvc.c_name AS customer_name,
    hvc.total_orders,
    hvc.total_spent
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    HighValueCustomers hvc ON hvc.total_orders > 5
WHERE 
    (ss.total_supplycost IS NOT NULL OR hvc.total_spent IS NOT NULL)
    AND n.n_name IS NOT NULL
ORDER BY 
    n.n_name, ss.unique_parts DESC, hvc.total_spent DESC;
