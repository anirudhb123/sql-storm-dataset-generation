WITH RECURSIVE price_summary AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost) AS total_supplycost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey, p.p_name
    HAVING
        SUM(ps.ps_supplycost) > 1000
),
ranked_orders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
nation_supplier AS (
    SELECT
        n.n_name,
        COUNT(s.s_suppkey) AS supplier_count,
        COALESCE(AVG(s.s_acctbal), 0) AS avg_acctbal
    FROM
        nation n
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        n.n_name
)
SELECT
    ns.n_name,
    ps.p_name,
    ps.total_supplycost,
    ro.total_sales,
    CASE 
        WHEN ro.sales_rank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS sales_category,
    ns.avg_acctbal
FROM
    price_summary ps
JOIN
    ranked_orders ro ON ps.p_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_supplycost = ps.total_supplycost ORDER BY ps_supplycost DESC LIMIT 1)
LEFT JOIN
    nation_supplier ns ON ns.supplier_count > 10
WHERE
    ps.total_supplycost IS NOT NULL
ORDER BY
    ns.n_name, ps.p_name;
