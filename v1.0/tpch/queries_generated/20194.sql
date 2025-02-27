WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        DENSE_RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank_within_region
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
),

AggregatedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        MAX(ps.ps_supplycost) AS max_supplycost,
        MIN(ps.ps_supplycost) AS min_supplycost,
        STRING_AGG(ps.ps_comment, '; ') AS all_comments
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey, p.p_name
),

FilteredOrders AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderdate,
        LEAD(o.o_totalprice) OVER (ORDER BY o.o_orderdate) AS next_order_total
    FROM
        orders o
    WHERE
        o.o_orderstatus = 'O' AND
        o.o_orderdate >= DATE '2023-01-01'
)

SELECT
    r.s_suppkey,
    r.s_name,
    r.rank_within_region,
    ap.p_partkey,
    ap.p_name,
    ap.supplier_count,
    ap.total_cost,
    fo.o_orderkey,
    fo.o_totalprice,
    fo.next_order_total,
    CASE 
        WHEN r.rank_within_region IS NULL THEN 'No Supplier Rank'
        ELSE 'Ranked Supplier'
    END AS supplier_rank_status
FROM
    RankedSuppliers r
FULL OUTER JOIN
    AggregatedParts ap ON r.s_suppkey IS NOT NULL
LEFT JOIN 
    FilteredOrders fo ON r.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = ap.p_partkey)
WHERE
    (fo.o_totalprice IS NULL OR fo.o_totalprice > 1000) AND
    (ap.total_cost > 0 OR (ap.total_cost = 0 AND r.rank_within_region IS NOT NULL))
ORDER BY
    r.rank_within_region, ap.total_cost DESC NULLS LAST;
