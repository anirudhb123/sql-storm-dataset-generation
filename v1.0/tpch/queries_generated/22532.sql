WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 30
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        SUM(ps.ps_availqty) AS total_availqty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        AVG(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
), 
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    ss.s_name,
    ss.avg_supplycost,
    cos.order_count,
    cos.total_spent,
    CASE 
        WHEN cos.total_spent IS NULL THEN 'No Purchases'
        WHEN cos.total_spent > 10000 THEN 'High Spender'
        ELSE 'Regular Spender'
    END AS customer_segment
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierStats ss ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < ss.avg_supplycost)
LEFT JOIN 
    CustomerOrderStats cos ON EXISTS (
        SELECT 1 FROM lineitem l 
        WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cos.c_custkey)
        AND l.l_discount > 0.05
    )
WHERE 
    rp.price_rank = 1
ORDER BY 
    rp.p_retailprice DESC, ss.avg_supplycost ASC, cos.total_spent DESC;
