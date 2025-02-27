WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        AVG(s.s_acctbal) AS avg_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
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
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND (c.c_acctbal IS NOT NULL OR c.c_name LIKE '%Corp%')
    GROUP BY 
        c.c_custkey
),
HighValueNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        SUM(s.s_acctbal) > 100000
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_mfgr,
    ss.suppkey,
    ss.avg_acctbal,
    co.total_spent,
    hn.n_name,
    CASE 
        WHEN co.total_spent > 5000 THEN 'High Roller'
        WHEN co.total_spent BETWEEN 1000 AND 5000 THEN 'Mid Tier'
        ELSE 'Budget'
    END AS customer_tier,
    CASE 
        WHEN rp.price_rank = 1 THEN 'Most Expensive'
        ELSE 'Standard'
    END AS part_price_category
FROM 
    RankedParts rp
JOIN 
    SupplierStats ss ON rp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ss.s_suppkey LIMIT 1)
LEFT JOIN 
    CustomerOrders co ON co.total_spent IS NOT NULL 
LEFT JOIN 
    HighValueNations hn ON hn.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey LIMIT 1)
WHERE 
    rp.p_brand LIKE 'Brand%'
    AND rp.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type = rp.p_type)
ORDER BY 
    rp.p_partkey, ss.avg_acctbal DESC, co.total_spent ASC;
