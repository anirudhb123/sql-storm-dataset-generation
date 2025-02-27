WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
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
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    ss.s_name AS supplier_name,
    ss.total_available_quantity,
    ss.avg_supply_cost,
    cos.c_name AS customer_name,
    cos.total_orders,
    cos.total_spent
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    SupplierSummary ss ON ss.s_suppkey = s.s_suppkey
JOIN 
    CustomerOrderSummary cos ON cos.total_spent >= ss.avg_supply_cost
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC, ss.total_available_quantity DESC;
