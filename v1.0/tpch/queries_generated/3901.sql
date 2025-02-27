WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank_per_type
    FROM 
        part p
), 
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
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
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2)
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    COALESCE(sa.total_avail_qty, 0) AS available_quantity,
    COALESCE(sa.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(co.order_count, 0) AS customer_order_count,
    COALESCE(co.total_spent, 0) AS customer_total_spent
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierAvailability sa ON rp.p_partkey = sa.ps_partkey
LEFT JOIN 
    CustomerOrders co ON co.order_count > 0
WHERE 
    rp.rank_per_type <= 5
ORDER BY 
    rp.p_retailprice DESC, 
    co.total_spent DESC;
