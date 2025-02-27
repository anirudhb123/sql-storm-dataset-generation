WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20 AND 
        p.p_comment LIKE '%special%'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_size,
    rp.p_retailprice,
    sd.s_name AS supplier_name,
    sd.total_supply_cost,
    co.c_name AS customer_name,
    co.total_order_value
FROM 
    RankedParts rp
JOIN 
    SupplierDetails sd ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
JOIN 
    CustomerOrders co ON co.total_order_value > (SELECT AVG(total_order_value) FROM CustomerOrders)
WHERE 
    rp.rnk <= 5
ORDER BY 
    rp.p_retailprice DESC, sd.total_supply_cost DESC;
