WITH CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
PopularParts AS (
    SELECT
        ps.ps_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        partsupp ps
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        ps.ps_partkey, p.p_name
),
RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT
    co.c_name,
    co.order_count,
    co.total_spent,
    pp.p_name,
    pp.total_available,
    pp.avg_supply_cost,
    rs.s_name AS top_supplier
FROM
    CustomerOrders co
FULL OUTER JOIN
    PopularParts pp ON pp.total_available > 1000
LEFT JOIN
    RankedSuppliers rs ON rs.supplier_rank = 1
WHERE
    co.total_spent IS NOT NULL OR rs.s_suppkey IS NULL
ORDER BY
    co.total_spent DESC NULLS LAST,
    pp.avg_supply_cost ASC;
