WITH RankedPartners AS (
    SELECT
        ps.partkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) as rank
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
OrderAggregates AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_count,
        MAX(l.l_shipdate) AS latest_shipdate
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey
),
FilteredCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        (CASE 
            WHEN c.c_acctbal IS NULL THEN 'No balance' 
            WHEN c.c_acctbal < 1000 THEN 'Low balance' 
            ELSE 'Sufficient balance' 
        END) AS balance_status
    FROM
        customer c
    WHERE
        c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 1)
),
RegionStats AS (
    SELECT
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nations_count,
        AVG(s.s_acctbal) AS avg_supplier_balance
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        r.r_name
)
SELECT
    f.c_name,
    f.c_acctbal,
    f.balance_status,
    o.revenue,
    r.nations_count,
    r.avg_supplier_balance,
    p.s_name AS top_supplier
FROM
    FilteredCustomers f
LEFT JOIN
    OrderAggregates o ON f.c_custkey = (
        SELECT
            o.o_custkey
        FROM
            orders o
        ORDER BY
            o.o_orderdate DESC
        LIMIT 1
    )
JOIN
    RankedPartners p ON f.c_custkey = p.ps_partkey
JOIN
    RegionStats r ON r.nations_count >= 1
WHERE
    (f.c_acctbal IS NOT NULL OR f.balance_status = 'Low balance')
    AND (o.revenue IS NOT NULL AND o.revenue > 1000)
ORDER BY
    o.revenue DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
