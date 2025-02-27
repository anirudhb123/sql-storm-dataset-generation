WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        total_supply_value > 50000
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
CombinedMetrics AS (
    SELECT 
        rp.p_name,
        rp.p_brand,
        rp.p_type,
        hvs.s_name AS supplier_name,
        coc.order_count
    FROM 
        RankedParts rp
    JOIN 
        HighValueSuppliers hvs ON rp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = hvs.s_suppkey ORDER BY ps.ps_supplycost DESC LIMIT 1)
    LEFT JOIN 
        CustomerOrderCount coc ON hvs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey ORDER BY ps.ps_supplycost DESC LIMIT 1)
    WHERE 
        rp.price_rank <= 10
)
SELECT 
    p_name, 
    p_brand, 
    p_type, 
    supplier_name, 
    COALESCE(order_count, 0) AS order_count
FROM 
    CombinedMetrics
ORDER BY 
    p_type, supplier_name;
