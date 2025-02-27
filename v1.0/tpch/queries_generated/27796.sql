WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        LENGTH(p.p_name) AS name_length,
        SUBSTRING(p.p_comment FROM 1 FOR 10) AS short_comment,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
MaxConsumerOrder AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
    ORDER BY
        total_spent DESC
    LIMIT 1
)
SELECT
    r.r_name,
    rp.p_name,
    rp.name_length,
    rp.short_comment,
    mc.c_name,
    mc.order_count,
    mc.total_spent
FROM
    region r
JOIN
    nation n ON n.n_regionkey = r.r_regionkey
JOIN
    supplier s ON s.s_nationkey = n.n_nationkey
JOIN
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
JOIN
    RankedParts rp ON rp.p_partkey = ps.ps_partkey
CROSS JOIN
    MaxConsumerOrder mc
WHERE
    rp.avg_supply_cost > 100.00
ORDER BY
    rp.name_length DESC, mc.total_spent DESC;
