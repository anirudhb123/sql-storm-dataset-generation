WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
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
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    sa.total_available_qty,
    sa.avg_supply_cost,
    co.c_name,
    co.total_orders,
    co.total_spent
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierAvailability sa ON rp.p_partkey = sa.ps_partkey
LEFT JOIN 
    CustomerOrders co ON co.total_spent > 10000
WHERE 
    rp.rn <= 5 
    AND rp.p_retailprice IS NOT NULL 
    AND (sa.total_available_qty IS NULL OR sa.total_available_qty > 50)
ORDER BY 
    rp.p_type, rp.p_retailprice DESC;
