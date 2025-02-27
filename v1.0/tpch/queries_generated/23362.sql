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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        MAX(s.s_acctbal) AS max_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
EconomicalParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice,
        ss.unique_parts,
        ss.avg_supplycost
    FROM 
        RankedParts rp
    JOIN 
        SupplierStats ss ON ss.unique_parts > 5 
    WHERE 
        rp.rn <= 3 AND 
        rp.p_retailprice < (SELECT MAX(p_retailprice) FROM part) / 2
),
FinalStats AS (
    SELECT 
        co.c_custkey,
        co.total_spent,
        ep.p_name,
        ep.p_retailprice,
        ep.unique_parts,
        ep.avg_supplycost,
        COALESCE((SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)), 0) AS lineitem_count
    FROM 
        CustomerOrders co
    LEFT JOIN 
        EconomicalParts ep ON ep.p_partkey IN (
            SELECT ps.ps_partkey FROM partsupp ps 
            WHERE ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
        )
)
SELECT 
    fs.c_custkey,
    fs.total_spent,
    fs.p_name,
    fs.p_retailprice,
    fs.lineitem_count,
    CASE 
        WHEN fs.total_spent > 1000 THEN 'High' 
        WHEN fs.total_spent IS NULL THEN 'Unknown' 
        ELSE 'Low' 
    END AS spending_category
FROM 
    FinalStats fs
WHERE 
    fs.total_spent IS NOT NULL
ORDER BY 
    fs.total_spent DESC, fs.lineitem_count ASC
LIMIT 50;
