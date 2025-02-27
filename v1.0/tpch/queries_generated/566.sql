WITH SupplierRevenue AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        COUNT(DISTINCT l.l_linenumber) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM
        orders o
    LEFT JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderstatus IN ('F', 'O')
    GROUP BY
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    r.r_name,
    COALESCE(sr.total_revenue, 0) AS total_revenue,
    COALESCE(os.order_total, 0) AS order_total,
    (COALESCE(sr.total_revenue, 0) + COALESCE(os.order_total, 0)) AS combined_revenue,
    CASE 
        WHEN COALESCE(sr.total_revenue, 0) > 0 THEN 'High'
        ELSE 'Low' 
    END AS revenue_category
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierRevenue sr ON sr.s_suppkey = (
        SELECT s.s_suppkey
        FROM supplier s
        WHERE s.s_nationkey = n.n_nationkey
        ORDER BY sr.total_revenue DESC
        LIMIT 1
    )
LEFT JOIN 
    OrderSummary os ON os.line_count > 0
WHERE 
    r.r_name LIKE '%Europe%'
ORDER BY 
    combined_revenue DESC, revenue_category ASC;
