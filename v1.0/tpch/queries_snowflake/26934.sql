WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_comment,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_comment) AS comment_length,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY LENGTH(p.p_name) DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 500.00)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 1000.00
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 500.00
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_comment,
    sd.s_name AS supplier_name,
    cs.c_name AS customer_name,
    cs.total_spent,
    cs.order_count
FROM 
    RankedParts rp
JOIN 
    SupplierDetails sd ON rp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey LIMIT 1)
JOIN 
    CustomerSummary cs ON cs.total_spent > 1000.00
WHERE 
    rp.brand_rank <= 5
ORDER BY 
    rp.name_length DESC, cs.total_spent DESC;
