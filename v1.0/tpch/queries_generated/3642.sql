WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
SuppliersWithProducts AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        p.p_name,
        p.p_brand,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    WHERE
        p.p_size >= 10
),
NationalStats AS (
    SELECT
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        AVG(s.s_acctbal) AS avg_supplier_balance
    FROM
        nation n
    JOIN
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        n.n_name
)
SELECT
    r.r_name,
    ns.customer_count,
    ns.avg_supplier_balance,
    SUM(wo.total_revenue) AS total_order_revenue
FROM
    region r
LEFT JOIN
    NationalStats ns ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = 'Americas')
LEFT JOIN
    RankedOrders wo ON RANK() OVER (PARTITION BY ns.n_name ORDER BY wo.total_revenue DESC) <= 5
GROUP BY
    r.r_name, ns.customer_count, ns.avg_supplier_balance
HAVING
    SUM(wo.total_revenue) IS NOT NULL
ORDER BY
    ns.customer_count DESC, total_order_revenue DESC;
