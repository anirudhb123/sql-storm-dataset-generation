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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
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
        s.s_comment
    FROM
        supplier s
    WHERE
        LENGTH(s.s_name) > 10 AND
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        o.o_shippriority
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_totalprice > 500.00 AND
        c.c_mktsegment = 'BUILDING'
)
SELECT
    r.r_name AS Region,
    COUNT(DISTINCT f.s_suppkey) AS SupplierCount,
    COUNT(DISTINCT co.o_orderkey) AS OrderCount,
    SUM(co.o_totalprice) AS TotalRevenue,
    STRING_AGG(DISTINCT rp.p_name) AS TopProducts
FROM
    RankedParts rp
JOIN
    FilteredSuppliers f ON f.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey)
JOIN
    nation n ON f.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN
    CustomerOrders co ON co.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = rp.p_partkey)
GROUP BY
    r.r_name
ORDER BY
    TotalRevenue DESC;
