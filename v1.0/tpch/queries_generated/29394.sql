WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
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
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),

CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS completed_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    rp.p_name,
    rp.p_retailprice,
    sd.s_name,
    cs.c_name,
    cs.total_spent,
    cs.completed_orders
FROM 
    RankedParts rp
JOIN 
    SupplierDetails sd ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
JOIN 
    CustomerStats cs ON cs.total_spent > 5000
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.p_retailprice DESC, cs.total_spent DESC;
