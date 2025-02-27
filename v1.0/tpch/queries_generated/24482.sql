WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        p.p_retailprice,
        p.p_size,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_by_price,
        COUNT(*) OVER (PARTITION BY p.p_brand) AS total_parts
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT ps.ps_supplycost FROM partsupp ps WHERE ps.ps_availqty > 0)
),

SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),

OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)

SELECT 
    rp.p_partkey,
    rp.p_name,
    sd.s_name AS supplier_name,
    sd.nation_name,
    os.total_order_value,
    os.item_count,
    CASE 
        WHEN os.o_orderstatus = 'F' THEN 'Finalized'
        WHEN os.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Unknown Status'
    END AS order_status
FROM RankedParts rp
LEFT JOIN SupplierDetails sd ON rp.p_brand = SUBSTRING(sd.s_name, 1, 5)
LEFT JOIN OrderSummary os ON os.o_orderkey = (
    SELECT o.o_orderkey
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_partkey = rp.p_partkey
    ORDER BY o.o_orderdate DESC
    LIMIT 1
)
WHERE rp.rank_by_price <= 5
  AND (disallowed_due_to NULL IS NULL OR rp.p_retailprice < 100.00)
ORDER BY rp.p_partkey, sd.rank DESC, os.total_order_value DESC;
