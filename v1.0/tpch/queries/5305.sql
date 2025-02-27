
WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS region_rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        COUNT(rs.s_name) AS top_supplier_count,
        SUM(rs.total_supply_cost) AS total_cost
    FROM
        region r
    LEFT JOIN
        RankedSuppliers rs ON r.r_regionkey = rs.region_rank
    WHERE
        rs.region_rank <= 5
    GROUP BY
        r.r_regionkey, r.r_name
)
SELECT
    r.r_name,
    ts.top_supplier_count,
    ts.total_cost,
    COUNT(o.o_orderkey) AS order_count,
    AVG(o.o_totalprice) AS avg_order_value
FROM
    TopSuppliers ts
JOIN
    region r ON ts.r_regionkey = r.r_regionkey
LEFT JOIN
    orders o ON o.o_orderkey IN (
        SELECT l.l_orderkey
        FROM lineitem l
        JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
        WHERE s.s_nationkey IN (
            SELECT n.n_nationkey
            FROM nation n
            WHERE n.n_regionkey = r.r_regionkey
        )
    )
GROUP BY
    r.r_name, ts.top_supplier_count, ts.total_cost
ORDER BY
    ts.total_cost DESC,
    order_count DESC;
