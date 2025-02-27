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
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING(p.p_name, 1, 3) ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100)
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        AVG(s.s_acctbal) AS avg_acctbal,
        COUNT(s.s_suppkey) AS total_suppliers
    FROM supplier s
    GROUP BY s.s_nationkey
),
TopNations AS (
    SELECT 
        n.n_name,
        n.n_regionkey,
        ss.avg_acctbal,
        ss.total_suppliers
    FROM nation n
    JOIN SupplierStats ss ON n.n_nationkey = ss.s_nationkey
    WHERE ss.avg_acctbal > (SELECT AVG(s.s_acctbal) FROM supplier s)
),
PartSupplierDetails AS (
    SELECT 
        pp.p_partkey,
        COUNT(ps.ps_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers
    FROM RankedParts pp
    JOIN partsupp ps ON pp.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY pp.p_partkey
)
SELECT 
    tn.n_name,
    tn.n_regionkey,
    p.p_name,
    p.p_retailprice,
    ps.supplier_count,
    ps.suppliers
FROM TopNations tn
JOIN PartSupplierDetails ps ON tn.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA') 
JOIN RankedParts p ON ps.p_partkey = p.p_partkey
WHERE p.rn <= 5
ORDER BY tn.n_name, p.p_retailprice DESC;
