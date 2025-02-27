WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL AND 
        p.p_size > 10
),
SupplierWithOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerBalances AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN c.c_acctbal < 0 THEN 'Low Balance'
            WHEN c.c_acctbal BETWEEN 0 AND 100 THEN 'Medium Balance'
            ELSE 'High Balance'
        END AS balance_status
    FROM 
        customer c
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    sup.s_name AS supplier_name,
    sup.order_count,
    cb.c_name AS customer_name,
    cb.balance_status
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierWithOrders sup ON EXISTS (
        SELECT 1 
        FROM partsupp ps 
        WHERE ps.ps_partkey = rp.p_partkey 
        AND ps.ps_suppkey = sup.s_suppkey
    )
LEFT JOIN 
    customer cb ON cb.c_custkey = (SELECT MIN(o.o_custkey) 
                                     FROM orders o 
                                     WHERE o.o_orderkey IN (SELECT l.l_orderkey 
                                                             FROM lineitem l 
                                                             WHERE l.l_partkey = rp.p_partkey))
WHERE 
    rp.price_rank <= 5 
    AND (sup.order_count > 0 OR sup.s_name IS NULL)
ORDER BY 
    rp.p_retailprice DESC, 
    cb.balance_status;
