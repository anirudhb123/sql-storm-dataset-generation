WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        p.p_comment, 
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%widget%'
),
CustomerSummary AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ps.ps_supplycost, 
        p.p_name, 
        p.p_mfgr
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    rp.p_partkey, 
    rp.p_name, 
    rp.p_retailprice, 
    cs.order_count, 
    cs.total_spent,
    spd.s_name,
    spd.ps_supplycost
FROM 
    RankedParts rp
JOIN 
    CustomerSummary cs ON cs.total_spent > 1000 
JOIN 
    SupplierPartDetails spd ON spd.p_mfgr = (SELECT 
                                                  p_mfgr 
                                              FROM 
                                                  part 
                                              WHERE 
                                                  p_partkey = rp.p_partkey)
WHERE 
    rp.rank <= 5 
ORDER BY 
    rp.p_retailprice DESC, cs.total_spent DESC;
