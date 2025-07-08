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
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rank_by_retailprice
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        n.n_name AS supplier_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
AggregatedOrders AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice) AS total_extended_price,
        MAX(l.l_discount) AS max_discount,
        MIN(l.l_tax) AS min_tax
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.p_mfgr,
    r.p_brand,
    r.p_type,
    f.s_name AS supplier_name,
    f.s_address AS supplier_address,
    a.lineitem_count,
    a.total_extended_price,
    a.max_discount,
    a.min_tax
FROM 
    RankedParts r
JOIN 
    FilteredSuppliers f ON r.p_partkey IN (SELECT ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = f.s_suppkey)
JOIN 
    AggregatedOrders a ON a.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = r.p_partkey)
WHERE 
    r.rank_by_retailprice <= 5
ORDER BY 
    r.p_brand, a.total_extended_price DESC;
