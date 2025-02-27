WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY LENGTH(p.p_name) DESC) AS rn
    FROM
        part p
    WHERE
        LENGTH(p.p_name) > 10
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM
        supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, n.n_name, r.r_name
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name, c.c_mktsegment
)
SELECT
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    rp.p_retailprice,
    rp.p_comment,
    sd.s_name AS supplier_name,
    sd.nation_name,
    sd.region_name,
    cd.c_name AS customer_name,
    cd.total_orders,
    cd.total_spent
FROM
    RankedParts rp
JOIN SupplierDetails sd ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
JOIN CustomerDetails cd ON cd.total_orders > 0
WHERE
    rp.rn = 1
ORDER BY
    rp.p_retailprice DESC, sd.total_supply_cost ASC;
