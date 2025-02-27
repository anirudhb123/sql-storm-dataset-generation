WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON p.p_partkey = ps.ps_partkey
),
RecentOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) AS order_rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderstatus IN ('O', 'F')
),
MaxOrderValues AS (
    SELECT
        ro.o_orderkey,
        ro.o_totalprice,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_line_price
    FROM
        RecentOrders ro
    LEFT JOIN
        lineitem l ON ro.o_orderkey = l.l_orderkey
    GROUP BY
        ro.o_orderkey, ro.o_totalprice
    HAVING
        total_line_price > (SELECT AVG(total_line_price) FROM (
            SELECT
                SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price
            FROM
                lineitem l
            GROUP BY
                l.l_orderkey
        ) avg_sub)
),
OddOrderTotal AS (
    SELECT DISTINCT
        o.o_orderkey,
        o.o_totalprice,
        CASE
            WHEN o.o_totalprice > 5000 THEN 'High'
            ELSE 'Low'
        END AS price_category
    FROM
        orders o
    WHERE
        o.o_totalprice IS NOT NULL
        AND MOD(o.o_totalprice, 2) = 1
),
FinalReport AS (
    SELECT
        ro.o_orderkey,
        ro.o_totalprice,
        s.s_name AS supplier_name,
        MAX(rv.rank_acctbal) AS supplier_rank,
        oo.price_category
    FROM
        MaxOrderValues ro
    LEFT JOIN
        RankedSuppliers s ON s.rank_acctbal = 1
    LEFT JOIN
        OddOrderTotal oo ON ro.o_orderkey = oo.o_orderkey
    GROUP BY
        ro.o_orderkey, ro.o_totalprice, oo.price_category, s.s_name
    HAVING
        s.s_name IS NOT NULL OR oo.price_category IS NOT NULL
)
SELECT
    DISTINCT f.o_orderkey,
    f.o_totalprice,
    CASE
        WHEN f.price_category IS NOT NULL THEN CONCAT(f.price_category, ' Order')
        ELSE 'No Valid Category'
    END AS order_category,
    f.supplier_name,
    COALESCE(f.supplier_rank, 0) AS supplier_rank
FROM
    FinalReport f
WHERE
    EXISTS (
        SELECT 1
        FROM supplier s
        WHERE s.s_name = f.supplier_name
        AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    )
ORDER BY
    f.o_orderkey DESC;
