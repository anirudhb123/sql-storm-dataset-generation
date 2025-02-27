WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
SupplierPart AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerStats AS (
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
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    COALESCE(ss.total_avail_qty, 0) AS available_quantity,
    COALESCE(ss.avg_supply_cost, 0) AS average_supply_cost,
    cs.order_count,
    cs.total_spent,
    ro.o_orderdate,
    ro.o_orderstatus
FROM 
    part p
LEFT JOIN 
    SupplierPart ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN 
    CustomerStats cs ON cs.order_count > 0
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey = (
        SELECT MAX(o_orderkey) 
        FROM orders 
        WHERE o_orderkey IN (
            SELECT l_orderkey 
            FROM lineitem 
            WHERE l_partkey = p.p_partkey
        )
    )
WHERE 
    (p.p_size >= 10 AND p.p_size <= 20) OR p.p_container IS NULL
ORDER BY 
    p.p_name, 
    cs.total_spent DESC NULLS LAST;
