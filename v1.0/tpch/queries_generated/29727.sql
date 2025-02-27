WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice > 100
),
SupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING total_orders > 5
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    rp.p_retailprice,
    rp.p_comment,
    sc.total_suppliers,
    cus.c_name,
    cus.total_orders,
    cus.total_spent
FROM RankedParts rp
JOIN SupplierCount sc ON rp.p_partkey = sc.ps_partkey
JOIN CustomerOrderSummary cus ON rand() * (SELECT COUNT(*) FROM customer) = cus.c_custkey
WHERE rp.price_rank <= 5
ORDER BY rp.p_retailprice DESC, cus.total_spent DESC;
