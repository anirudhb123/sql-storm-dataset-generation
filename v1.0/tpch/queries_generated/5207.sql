WITH ranked_orders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
),
top_orders AS (
    SELECT
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        n.n_name,
        r.c_name
    FROM
        ranked_orders r
    JOIN
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE
        r.rn <= 10
),
supplier_parts AS (
    SELECT
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        ps.ps_supplycost
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE
        ps.ps_availqty > 0
),
order_details AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM
        lineitem l
    WHERE
        l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2023-12-31'
    GROUP BY
        l.l_orderkey
)
SELECT
    oo.o_orderkey,
    oo.o_orderdate,
    oo.o_totalprice,
    oo.c_name AS customer_name,
    oo.n_name AS nation_name,
    SUM(od.revenue) AS total_revenue,
    COUNT(DISTINCT sp.s_suppkey) AS supplier_count
FROM
    top_orders oo
LEFT JOIN
    order_details od ON oo.o_orderkey = od.l_orderkey
LEFT JOIN
    supplier_parts sp ON sp.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = oo.o_orderkey)
GROUP BY
    oo.o_orderkey, oo.o_orderdate, oo.o_totalprice, oo.c_name, oo.n_name
ORDER BY
    total_revenue DESC
LIMIT 50;
