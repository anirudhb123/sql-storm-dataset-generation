WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 0
),
CustomerOrders AS (
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
OrdersWithDiscount AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS discounted_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
)
SELECT 
    r.s_name,
    p.p_name,
    COALESCE(c.order_count, 0) AS customer_order_count,
    COALESCE(c.total_spent, 0) AS customer_total_spent,
    d.discounted_price,
    CASE 
        WHEN r.rank = 1 THEN 'Lowest Cost Supplier'
        ELSE 'Other Supplier'
    END AS supplier_type
FROM 
    RankedSuppliers r
JOIN 
    part p ON r.s_suppkey = p.p_partkey
LEFT JOIN 
    CustomerOrders c ON c.c_custkey IN (SELECT c.custkey FROM HighValueCustomers hvc WHERE hvc.c_custkey = c.c_custkey)
LEFT JOIN 
    OrdersWithDiscount d ON d.o_orderkey = r.s_suppkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    r.s_name, p.p_name;
