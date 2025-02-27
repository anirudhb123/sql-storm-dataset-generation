WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    ss.s_name,
    ss.total_supplycost,
    cs.order_count,
    CASE 
        WHEN cs.order_count IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS Order_Status
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierStats ss ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_name LIKE '%Supplier%'))
LEFT JOIN 
    CustomerOrderCounts cs ON cs.order_count >= 1
WHERE 
    rp.rank <= 3
ORDER BY 
    rp.p_retailprice DESC, ss.total_supplycost ASC;
