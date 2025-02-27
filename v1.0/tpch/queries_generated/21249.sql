WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 20
    AND p.p_retailprice IS NOT NULL
),
TopManufacturers AS (
    SELECT 
        p.p_mfgr,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    JOIN RankedParts rp ON l.l_partkey = rp.p_partkey
    GROUP BY p.p_mfgr
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
LatestOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS recent_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'P')
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown'
            ELSE CAST(s.s_acctbal AS varchar)
        END AS acctbal_info
    FROM supplier s
    WHERE EXISTS (
        SELECT 1
        FROM partsupp ps
        WHERE ps.ps_suppkey = s.s_suppkey
        AND ps.ps_availqty < 100
    )
),
FinalResults AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        tm.total_revenue,
        ROW_NUMBER() OVER (PARTITION BY tm.p_mfgr ORDER BY tm.total_revenue DESC) AS mfg_rank
    FROM RankedParts rp
    JOIN TopManufacturers tm ON rp.p_mfgr = tm.p_mfgr
    WHERE rp.rn <= 5
)
SELECT 
    fr.p_partkey,
    fr.p_name,
    fr.total_revenue,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    COALESCE(la.o_orderdate, 'N/A') AS latest_order_date
FROM FinalResults fr
LEFT JOIN SupplierDetails s ON fr.p_partkey = s.s_suppkey
LEFT JOIN LatestOrders la ON la.o_orderkey = fr.p_partkey
WHERE fr.total_revenue IS NOT NULL
AND fr.mfg_rank <= 3
ORDER BY fr.total_revenue DESC, fr.p_name ASC;
