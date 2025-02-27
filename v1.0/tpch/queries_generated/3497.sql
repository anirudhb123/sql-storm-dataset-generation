WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
),
SupplierAgg AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    COALESCE(SA.total_available, 0) AS total_available,
    COALESCE(SA.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(CO.order_count, 0) AS customer_order_count,
    COALESCE(CO.total_spent, 0.00) AS total_spent,
    R.order_rank
FROM 
    part p
LEFT JOIN 
    SupplierAgg SA ON p.p_partkey = SA.ps_partkey
LEFT JOIN 
    CustomerOrders CO ON p.p_partkey = CO.c_custkey
JOIN 
    RankedOrders R ON R.o_orderkey = CO.c_custkey
WHERE 
    (p.p_size > 10 OR p.p_retailprice < 50.00)
    AND R.order_rank <= 10
ORDER BY 
    p.p_brand, p.p_name;
