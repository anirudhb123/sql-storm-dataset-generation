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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.p_brand) AS brand_count
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 50
),
HighPriceSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 1))
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        c.c_acctbal,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returns_count
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, c.c_name, c.c_acctbal
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
FinalResult AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.p_brand,
        rp.p_type,
        hp.s_name,
        hp.ps_supplycost,
        COALESCE(co.total_spent, 0) AS total_spent,
        co.returns_count
    FROM RankedParts rp
    LEFT JOIN HighPriceSuppliers hp ON rp.p_partkey = hp.ps_partkey AND hp.rank = 1
    LEFT JOIN CustomerOrders co ON rp.p_partkey IN (
        SELECT DISTINCT l.l_partkey
        FROM lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_orderstatus = 'F' AND l.l_shipdate < CURRENT_DATE
    )
    WHERE rp.rn <= 10
)
SELECT 
    *,
    CASE 
        WHEN total_spent > 20000 THEN 'VIP Customer'
        WHEN returns_count > 5 THEN 'High Returns'
        ELSE 'Regular'
    END AS customer_category
FROM FinalResult
ORDER BY rp_brand, total_spent DESC, p_retailprice ASC;
