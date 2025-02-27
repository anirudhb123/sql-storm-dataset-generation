WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_size,
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_nationkey
),
CustomerOrderSummary AS (
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
    HAVING 
        SUM(o.o_totalprice) > 1000
)
SELECT 
    n.n_name,
    ps.ps_partkey,
    rp.p_name,
    rp.p_retailprice,
    ss.supplier_count,
    os.order_count,
    os.total_spent
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierStats ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN 
    CustomerOrderSummary os ON os.c_custkey = (SELECT o.o_custkey 
                                                 FROM orders o 
                                                 WHERE o.o_orderkey = (SELECT MAX(o2.o_orderkey) 
                                                                       FROM orders o2 
                                                                       WHERE o2.o_custkey = os.c_custkey))
WHERE 
    rp.price_rank <= 10
    AND n.n_name IS NOT NULL
ORDER BY 
    n.n_name, rp.p_retailprice DESC;
