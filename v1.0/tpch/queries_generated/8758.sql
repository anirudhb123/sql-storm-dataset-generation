WITH ranked_orders AS (
    SELECT
        o.o_orderkey,
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY
        o.o_orderkey, c.c_nationkey
),
top_nations AS (
    SELECT
        n.n_name,
        SUM(r.revenue) AS total_revenue
    FROM
        ranked_orders r
    JOIN
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE
        r.revenue_rank <= 5
    GROUP BY
        n.n_name
)
SELECT
    n.n_name,
    n.total_revenue,
    r.r_comment
FROM
    top_nations n
JOIN
    region r ON n.r_regionkey = (SELECT r_regionkey FROM nation WHERE n_nationkey = n.c_nationkey)
ORDER BY
    total_revenue DESC;
