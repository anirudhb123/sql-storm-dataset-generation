WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(ps.ps_partkey) AS part_count
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
),
LineItemAnalysis AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS item_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM
        lineitem l
    GROUP BY
        l.l_orderkey
)
SELECT
    r.r_name AS region,
    n.n_name AS nation,
    ss.s_name AS supplier_name,
    cs.c_custkey AS customer_id,
    cs.total_spent,
    cs.order_count,
    la.total_revenue,
    la.item_count,
    la.avg_quantity
FROM
    region r
JOIN
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN
    supplier ss ON ss.s_nationkey = n.n_nationkey
LEFT JOIN
    CustomerOrders cs ON cs.c_custkey = (
        SELECT
            c.c_custkey
        FROM
            customer c
        WHERE
            c.c_nationkey = n.n_nationkey
        ORDER BY
            c.c_acctbal DESC
        LIMIT 1
    )
LEFT JOIN
    LineItemAnalysis la ON la.l_orderkey = (
        SELECT
            o.o_orderkey
        FROM
            orders o
        WHERE
            o.o_custkey = cs.c_custkey
        ORDER BY
            o.o_orderdate DESC
        LIMIT 1
    )
WHERE
    ss.total_supplycost IS NOT NULL OR cs.total_spent IS NOT NULL
ORDER BY
    r.r_name, n.n_name, cs.total_spent DESC;
