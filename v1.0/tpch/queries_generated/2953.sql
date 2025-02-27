WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
),
PartStats AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey, p.p_name
),
CustomerOrderStats AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    ps.p_name,
    ps.total_available,
    ps.avg_supply_cost,
    COALESCE(cos.total_orders, 0) AS order_count,
    COALESCE(cos.total_spent, 0) AS total_spent,
    rs.s_name AS top_supplier
FROM
    PartStats ps
LEFT JOIN
    CustomerOrderStats cos ON ps.p_partkey IN (
        SELECT l.l_partkey
        FROM lineitem l
        WHERE l.l_orderkey IN (
            SELECT o.o_orderkey
            FROM orders o
            WHERE o.o_orderstatus = 'O'
        )
    )
LEFT JOIN
    RankedSuppliers rs ON rs.rank = 1 AND rs.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey = ps.p_partkey
    )
WHERE
    ps.total_available > 100
ORDER BY
    ps.avg_supply_cost DESC,
    total_spent DESC
LIMIT 50;
