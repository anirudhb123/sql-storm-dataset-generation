WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS BrandRank
    FROM part p
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey,
        SUBSTRING(s.s_comment, 1, 20) AS short_comment
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
AggregatedOrders AS (
    SELECT 
        o.o_orderkey, 
        COUNT(l.l_linenumber) AS line_item_count, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    r.r_name AS region_name,
    p.p_name AS part_name,
    fs.s_name AS supplier_name,
    ao.line_item_count,
    ao.total_revenue,
    p.BrandRank
FROM RankedParts p
JOIN FilteredSuppliers fs ON fs.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
JOIN AggregatedOrders ao ON ao.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = fs.s_nationkey))
JOIN region r ON r.r_regionkey = fs.s_nationkey
WHERE p.BrandRank <= 5
ORDER BY r.r_name, p.p_retailprice DESC;
