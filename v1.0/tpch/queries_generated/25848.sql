WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rank
    FROM 
        part p
),
CombinedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) as supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone
),
CustomerPurchaseSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) as customer_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
)
SELECT 
    rp.p_name,
    rp.p_mfgr,
    rp.p_brand,
    cs.s_name AS top_supplier,
    cps.c_name AS top_customer,
    cps.total_spent,
    cs.total_supply_value
FROM 
    RankedParts rp
JOIN 
    CombinedSuppliers cs ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = cs.s_suppkey)
JOIN 
    CustomerPurchaseSummary cps ON cps.order_count > 0
WHERE 
    rp.rank = 1 AND cs.supplier_rank = 1 AND cps.customer_rank = 1
ORDER BY 
    rp.p_name;
