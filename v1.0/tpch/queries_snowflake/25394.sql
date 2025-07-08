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
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_name LIKE '%Steel%'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
TopSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        COUNT(ps.ps_partkey) AS supply_count
    FROM SupplierDetails sd
    JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
    GROUP BY sd.s_suppkey, sd.s_name
    HAVING COUNT(ps.ps_partkey) > 10
),
OrderSummaries AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    ts.s_name,
    os.total_revenue,
    os.item_count,
    rp.p_comment
FROM RankedParts rp
JOIN TopSuppliers ts ON ts.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = rp.p_partkey
)
JOIN OrderSummaries os ON os.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_partkey = rp.p_partkey
)
WHERE rp.rn = 1
ORDER BY rp.p_retailprice DESC;
