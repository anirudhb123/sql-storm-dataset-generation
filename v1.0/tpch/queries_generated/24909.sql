WITH RECURSIVE CustomerHierarchy AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        0 AS level
    FROM
        customer c
    WHERE
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
    
    UNION ALL
    
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ch.level + 1
    FROM
        CustomerHierarchy ch
    JOIN
        customer c ON ch.c_custkey = c.c_custkey
    WHERE
        c.c_acctbal < ch.c_acctbal
),

PartPricing AS (
    SELECT
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        p.p_retailprice,
        (p.p_retailprice - ps.ps_supplycost) AS profit
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE
        ps.ps_availqty > 0
),

RegionalSales AS (
    SELECT
        n.n_name AS nation_name,
        SUM(line.l_extendedprice * (1 - line.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        lineitem line
    JOIN
        orders o ON line.l_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE
        line.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY
        n.n_name
)

SELECT
    rh.nation_name,
    rh.total_sales,
    COALESCE(NULLIF(pp.profit, NULL), 0) AS planned_profit
FROM
    RegionalSales rh
LEFT JOIN
    PartPricing pp ON rh.total_sales > pp.ps_supplycost
ORDER BY
    (CASE WHEN rh.total_sales IS NOT NULL THEN rh.total_sales ELSE -1 END) DESC,
    (CASE pp.p_partkey WHEN 0 THEN NULL ELSE pp.p_partkey END);
