WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size > 10
), ExtremeSupplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        MAX(ps.ps_supplycost) AS max_supplycost,
        MIN(ps.ps_availqty) AS min_availqty,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), OrderQuantities AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_quantity) AS total_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
), SupplierNation AS (
    SELECT 
        s.s_nationkey,
        AVG(s.s_acctbal) AS avg_acctbal,
        COUNT(*) AS supplier_count
    FROM supplier s
    GROUP BY s.s_nationkey
    HAVING AVG(s.s_acctbal) > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    es.max_supplycost,
    es.min_availqty,
    oq.total_quantity,
    COALESCE(sn.avg_acctbal, 0) AS avg_supplier_acctbal,
    CASE 
        WHEN es.unique_suppliers = 0 THEN 'No suppliers'
        ELSE 'Has suppliers' 
    END AS supplier_status
FROM RankedParts rp
LEFT JOIN ExtremeSupplier es ON rp.p_partkey = es.ps_partkey
LEFT JOIN OrderQuantities oq ON oq.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_orderstatus = 'O')
LEFT JOIN SupplierNation sn ON sn.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
WHERE rp.rn = 1 
AND (rp.p_retailprice BETWEEN 100 AND 500 OR es.max_supplycost IS NULL)
ORDER BY rp.p_retailprice DESC NULLS LAST
LIMIT 50;
