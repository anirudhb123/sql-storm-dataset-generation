WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size > 20
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (
        SELECT AVG(s1.s_acctbal)
        FROM supplier s1
        WHERE s1.s_nationkey = s.s_nationkey
    )
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    COALESCE(sa.total_available, 0) AS total_available,
    ts.s_name AS top_supplier,
    ts.s_acctbal AS supplier_acctbal
FROM RankedParts rp
LEFT JOIN SupplierAvailability sa ON rp.p_partkey = sa.ps_partkey
LEFT JOIN TopSuppliers ts ON ts.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = rp.p_partkey 
    ORDER BY ps.ps_supplycost ASC 
    LIMIT 1
)
WHERE rp.rn = 1
AND (rp.p_retailprice > 100.00 OR (rp.p_retailprice <= 100.00 AND sa.total_available > 50))
ORDER BY rp.p_retailprice DESC, ts.s_acctbal DESC;
