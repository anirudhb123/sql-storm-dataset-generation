WITH RECURSIVE price_analysis AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_supplycost,
        (p.p_retailprice - ps.ps_supplycost) AS profit_margin,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY (p.p_retailprice - ps.ps_supplycost) DESC) AS rn
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE
        ps.ps_availqty > 0
), discounted_orders AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice * (1 - CASE 
            WHEN o.o_orderstatus = 'F' THEN 0.1 
            WHEN o.o_orderstatus = 'P' THEN 0.2 
            ELSE 0 
        END) AS discounted_price,
        o.o_orderdate,
        c.c_name,
        c.c_acctbal
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderstatus IN ('F', 'P') AND c.c_acctbal IS NOT NULL
), suspicious_activity AS (
    SELECT
        o.o_orderkey,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice) AS total_price
    FROM
        orders o
    LEFT JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey
    HAVING
        COUNT(l.l_orderkey) > 5 AND SUM(l.l_extendedprice) > 1000
), top_suppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
    ORDER BY
        total_supply_cost DESC
    LIMIT 10
)
SELECT
    pa.p_name,
    COALESCE(d.discounted_price, 0) AS adjusted_price,
    sa.line_count,
    sa.total_price,
    ts.s_name AS top_supplier,
    ts.total_supply_cost
FROM
    price_analysis pa
LEFT JOIN
    discounted_orders d ON pa.p_partkey = (
        SELECT
            l.l_partkey
        FROM
            lineitem l
        WHERE
            d.o_orderkey = l.l_orderkey
        LIMIT 1
    )
LEFT JOIN
    suspicious_activity sa ON d.o_orderkey = sa.o_orderkey
JOIN
    top_suppliers ts ON pa.p_partkey = (
        SELECT
            ps.ps_partkey
        FROM
            partsupp ps
        WHERE
            ps.ps_suppkey = ts.s_suppkey
        LIMIT 1
    )
WHERE
    pa.profit_margin IS NOT NULL
ORDER BY
    pa.profit_margin DESC, adjusted_price ASC;
