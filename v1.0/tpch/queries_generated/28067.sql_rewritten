WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_retailprice > 50.00
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name LIKE 'A%' AND s.s_acctbal > 10000.00
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY o.o_orderkey, o.o_totalprice
)
SELECT 
    rp.p_name,
    rp.p_brand,
    fs.s_name,
    od.o_orderkey,
    od.total_revenue,
    od.line_count
FROM RankedParts rp
JOIN FilteredSuppliers fs ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = fs.s_suppkey)
JOIN OrderDetails od ON rp.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = od.o_orderkey)
WHERE rp.rank <= 5
ORDER BY rp.p_brand, od.total_revenue DESC;