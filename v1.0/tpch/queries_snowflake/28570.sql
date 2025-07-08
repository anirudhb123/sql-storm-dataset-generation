
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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM
        part p
    WHERE
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) FROM part p2
        )
), 
SufficientSuppliers AS (
    SELECT
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey
    HAVING
        COUNT(DISTINCT ps.ps_suppkey) > 5
),
CustomerOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        c.c_name,
        c.c_address,
        c.c_nationkey
    FROM
        orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY
        o.o_orderkey, o.o_orderstatus, c.c_name, c.c_address, c.c_nationkey
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
)
SELECT
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    rp.p_retailprice,
    COUNT(DISTINCT co.o_orderkey) AS order_count,
    AVG(co.total_order_value) AS avg_order_value,
    r.r_name
FROM
    RankedParts rp
JOIN SufficientSuppliers ss ON rp.p_partkey = ss.ps_partkey
JOIN CustomerOrders co ON rp.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_suppkey IN (
        SELECT s.s_suppkey 
        FROM supplier s 
        WHERE s.s_nationkey = co.c_nationkey
    )
)
JOIN region r ON r.r_regionkey = (
    SELECT n.n_regionkey 
    FROM nation n 
    JOIN supplier s ON n.n_nationkey = s.s_nationkey 
    WHERE s.s_suppkey IN (
        SELECT DISTINCT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = rp.p_partkey
    ) 
    LIMIT 1
)
GROUP BY
    rp.p_name, rp.p_brand, rp.p_type, rp.p_retailprice, r.r_name
ORDER BY
    rp.p_retailprice DESC, order_count DESC;
