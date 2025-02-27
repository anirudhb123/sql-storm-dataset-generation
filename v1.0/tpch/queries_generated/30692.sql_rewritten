WITH RECURSIVE SupplierHierarchy AS (
    SELECT
        s.s_suppkey,
        0 AS level,
        s.s_name,
        s.s_acctbal
    FROM
        supplier s
    WHERE
        s.s_acctbal > 1000
    UNION ALL
    SELECT
        p.ps_suppkey,
        sh.level + 1,
        s.s_name,
        s.s_acctbal
    FROM
        partsupp p
    JOIN
        SupplierHierarchy sh ON p.ps_partkey = ANY(SELECT ps_partkey FROM partsupp WHERE ps_suppkey = sh.s_suppkey)
    JOIN
        supplier s ON p.ps_suppkey = s.s_suppkey
    WHERE
        s.s_acctbal > 1000
),
OrderAggregation AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        l.l_shipdate BETWEEN cast('1998-10-01' as date) - INTERVAL '6 months' AND cast('1998-10-01' as date)
    GROUP BY
        o.o_orderkey
),
FilteredRegions AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY
        r.r_regionkey, r.r_name
    HAVING
        COUNT(DISTINCT n.n_nationkey) > 1
)
SELECT
    sh.s_name,
    sh.level,
    ag.total_revenue,
    ag.customer_count,
    fr.r_name,
    fr.nation_count
FROM
    SupplierHierarchy sh
LEFT JOIN
    OrderAggregation ag ON ag.o_orderkey IN (SELECT DISTINCT o_orderkey FROM orders WHERE o_custkey = ANY(SELECT c_custkey FROM customer WHERE c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')))
LEFT JOIN
    FilteredRegions fr ON fr.r_regionkey = (SELECT r.r_regionkey FROM region r JOIN nation n ON r.r_regionkey = n.n_regionkey WHERE n.n_nationkey = sh.s_suppkey)
WHERE
    ag.total_revenue IS NOT NULL
ORDER BY
    total_revenue DESC
LIMIT 10;