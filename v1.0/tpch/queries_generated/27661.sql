WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        LENGTH(p.p_comment) > 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_total
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS supplier_region,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
)
SELECT 
    rp.p_name,
    rp.p_mfgr,
    rp.p_retailprice,
    co.c_name,
    co.order_count,
    co.avg_order_total,
    sd.supplier_region,
    sd.total_supply_value
FROM 
    RankedParts rp
JOIN 
    CustomerOrders co ON co.order_count > 5 
JOIN 
    SupplierDetails sd ON sd.total_supply_value > 10000
WHERE 
    rp.rnk <= 10
ORDER BY 
    rp.p_retailprice DESC, co.avg_order_total ASC;
