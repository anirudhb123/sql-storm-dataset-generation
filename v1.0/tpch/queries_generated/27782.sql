WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        p.p_mfgr,
        p.p_brand,
        SUBSTRING(p.p_comment, 1, 15) AS short_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        s.s_acctbal,
        LEFT(s.s_comment, 50) AS short_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rp.p_name,
    rp.p_type,
    rp.p_mfgr,
    rp.p_brand,
    sd.s_name AS supplier_name,
    sd.nation_name,
    cp.c_name AS customer_name,
    cp.total_spent,
    rp.short_comment AS part_comment,
    sd.short_comment AS supplier_comment
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    CustomerPurchases cp ON cp.order_count > 10
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_type, cp.total_spent DESC;
