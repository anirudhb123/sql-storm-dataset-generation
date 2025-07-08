WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM
        part p
    WHERE
        p.p_size > 10
        AND p.p_retailprice < 100.00
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        SUBSTRING(s.s_comment, 1, 20) AS short_comment
    FROM
        supplier s
    WHERE
        s.s_acctbal > 1000.00
),
CustomerDetails AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_address,
        n.n_name AS nation_name,
        c.c_phone,
        c.c_acctbal,
        c.c_mktsegment
    FROM
        customer c
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE
        c.c_acctbal > 2000.00
)
SELECT
    rp.p_name AS part_name,
    rp.p_mfgr AS manufacturer,
    sd.s_name AS supplier_name,
    cd.c_name AS customer_name,
    cd.nation_name,
    rp.p_retailprice,
    sd.short_comment,
    ROW_NUMBER() OVER (PARTITION BY rp.p_mfgr ORDER BY rp.p_retailprice ASC) AS part_rank
FROM
    RankedParts rp
JOIN
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN
    customer cu ON ps.ps_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cu.c_custkey LIMIT 1) LIMIT 1)
JOIN
    CustomerDetails cd ON cu.c_custkey = cd.c_custkey
WHERE
    rp.rn <= 5
ORDER BY
    rp.p_mfgr, part_rank;
