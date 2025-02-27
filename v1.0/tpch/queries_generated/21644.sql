WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
),
AggregatedOrders AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY
        o.o_orderkey
),
PartAvailability AS (
    SELECT
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey
),
FinalResults AS (
    SELECT
        p.p_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        pa.total_available_quantity,
        ao.total_revenue,
        ao.unique_customers
    FROM
        part p
    LEFT JOIN
        RankedSuppliers s ON p.p_partkey = ps.ps_partkey
    LEFT JOIN
        PartAvailability pa ON p.p_partkey = pa.p_partkey
    LEFT JOIN
        AggregatedOrders ao ON p.p_partkey = ao.o_orderkey
    GROUP BY
        p.p_name, pa.total_available_quantity, ao.total_revenue, ao.unique_customers
)
SELECT
    p_name,
    supplier_count,
    total_available_quantity,
    COALESCE(total_revenue, 0) AS total_revenue,
    COALESCE(unique_customers, 0) AS unique_customers,
    CASE 
        WHEN total_revenue IS NULL THEN 'No Revenue'
        WHEN total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue' 
    END AS revenue_category
FROM
    FinalResults
WHERE
    (supplier_count IS NULL OR supplier_count > 1)
    AND (total_available_quantity IS NOT NULL AND total_available_quantity > 0)
ORDER BY
    supplier_count DESC,
    total_revenue DESC NULLS LAST
LIMIT 100 OFFSET 10;
