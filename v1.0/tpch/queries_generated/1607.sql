WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM
        supplier s
),
HighValueParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey, p.p_name
    HAVING
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
OrdersInfo AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        COUNT(l.l_orderkey) AS line_count
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_custkey
)
SELECT
    c.c_name,
    c.c_acctbal,
    r.r_name,
    p.p_name,
    hvp.total_value,
    oi.order_value,
    oi.line_count
FROM
    customer c
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN
    RankedSuppliers rs ON c.c_nationkey = rs.s_suppkey
JOIN
    HighValueParts hvp ON hvp.p_partkey = rs.s_suppkey
JOIN
    OrdersInfo oi ON c.c_custkey = oi.o_custkey
WHERE
    rs.rn = 1
    AND c.c_acctbal IS NOT NULL
    AND hvp.total_value IS NOT NULL
ORDER BY
    order_value DESC
LIMIT 10;
