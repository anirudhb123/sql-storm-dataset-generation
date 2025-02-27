WITH ranked_orders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM
        orders AS o
    JOIN
        customer AS c ON o.o_custkey = c.c_custkey
    JOIN
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate, c.c_custkey, c.c_name
),
top_customers AS (
    SELECT
        rc.n_nationkey,
        n.n_name,
        ro.c_name,
        ro.total_revenue
    FROM
        ranked_orders AS ro
    JOIN
        nation AS n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = ro.c_custkey)
    JOIN
        ranked_orders AS rc ON rc.o_orderkey = ro.o_orderkey
    WHERE
        ro.revenue_rank <= 10
)
SELECT
    r.r_name,
    COUNT(DISTINCT tc.c_name) AS customer_count,
    SUM(tc.total_revenue) AS total_revenue_per_region
FROM
    region AS r
JOIN
    nation AS n ON r.r_regionkey = n.n_regionkey
JOIN
    top_customers AS tc ON n.n_nationkey = tc.n_nationkey
GROUP BY
    r.r_name
ORDER BY
    total_revenue_per_region DESC;
