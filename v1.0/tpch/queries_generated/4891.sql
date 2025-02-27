WITH region_summary AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM
        region r
    LEFT JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        r.r_regionkey, r.r_name
),
customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
lineitem_agg AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM
        lineitem l
    GROUP BY
        l.l_orderkey
),
final_report AS (
    SELECT
        rs.r_name,
        cs.c_name,
        coalesce(SUM(la.revenue), 0) AS total_revenue,
        rs.total_supplier_balance,
        cs.order_count,
        cs.total_spent
    FROM
        region_summary rs
    FULL OUTER JOIN
        customer_orders cs ON rs.nation_count = (SELECT COUNT(DISTINCT n.n_nationkey) FROM nation n WHERE n.n_regionkey = rs.r_regionkey)
    LEFT JOIN
        lineitem_agg la ON cs.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = la.l_orderkey LIMIT 1)
    GROUP BY
        rs.r_name, cs.c_name, rs.total_supplier_balance, cs.order_count, cs.total_spent
)
SELECT
    r_name,
    c_name,
    total_revenue,
    total_supplier_balance,
    order_count,
    total_spent
FROM
    final_report
WHERE
    total_revenue > 10000 AND total_supplier_balance IS NOT NULL
ORDER BY
    total_revenue DESC, total_supplier_balance DESC;
