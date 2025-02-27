
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_nationkey, 
        s.s_phone, 
        s.s_acctbal, 
        s.s_comment, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type,
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment
    FROM part p
    WHERE p.p_size > 10 AND p.p_retailprice < 100.00
),
SupplierAggregates AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    s.s_address AS supplier_address,
    s.s_phone AS supplier_phone,
    pa.total_availqty,
    pa.total_supplycost,
    r.r_name AS region_name
FROM FilteredParts p
JOIN SupplierAggregates pa ON p.p_partkey = pa.ps_partkey
JOIN RankedSuppliers s ON s.rank = 1 AND s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE s.s_acctbal > 5000.00
ORDER BY p.p_name, s.s_name;
