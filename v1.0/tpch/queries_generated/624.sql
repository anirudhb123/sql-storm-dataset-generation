WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        AVG(s.s_acctbal) AS avg_acct_balance
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
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY
        c.c_custkey
),
PartRevenue AS (
    SELECT
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM
        part p
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE
        l.l_shipdate >= '2023-01-01'
    GROUP BY
        p.p_partkey
)
SELECT
    ns.n_name AS nation_name,
    ss.s_name AS supplier_name,
    cs.c_custkey AS customer_id,
    cs.order_count,
    cs.total_spent,
    ps.total_supply_cost,
    pr.revenue
FROM
    nation ns
LEFT JOIN
    supplier ss ON ns.n_nationkey = ss.s_nationkey
LEFT JOIN
    customer cs ON ns.n_nationkey = cs.c_nationkey
LEFT JOIN
    SupplierStats ps ON ss.s_suppkey = ps.s_suppkey
LEFT JOIN
    PartRevenue pr ON ps.unique_parts > 5 AND ps.s_suppkey = cs.c_custkey
WHERE
    cs.total_spent IS NOT NULL
    AND cs.order_count > (
        SELECT AVG(order_count) FROM CustomerOrders
    )
ORDER BY
    ns.n_name, ss.s_name;
