WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS order_level
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    
    UNION ALL

    SELECT 
        co.c_custkey,
        co.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        co.order_level + 1
    FROM 
        CustomerOrders co
    JOIN 
        orders o ON co.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate > co.o_orderdate
),
AggregateOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierAvailability AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_suppkey,
        ps.ps_availqty,
        s.s_acctbal
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    co.c_name AS customer_name,
    ao.order_count,
    ao.total_spent,
    ao.avg_order_value,
    sa.p_name AS product_name,
    sa.ps_availqty,
    COALESCE(sa.s_acctbal, 0) AS supplier_account_balance,
    ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY ao.total_spent DESC) AS customer_rank
FROM 
    CustomerOrders co
JOIN 
    AggregateOrders ao ON co.c_custkey = ao.c_custkey
LEFT JOIN 
    SupplierAvailability sa ON co.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = sa.p_partkey)
WHERE 
    ao.total_spent > (SELECT AVG(total_spent) FROM AggregateOrders)
    AND (ao.order_count > 5 OR sa.ps_availqty > 100)
ORDER BY 
    ao.total_spent DESC;
