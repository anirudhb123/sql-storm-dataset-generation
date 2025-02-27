WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY p_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_by_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_suppkey, s.s_name, p.p_name
),
HighCostSuppliers AS (
    SELECT
        s_name,
        total_supply_cost
    FROM
        RankedSuppliers
    WHERE
        rank_by_cost = 1
)
SELECT
    c.c_name AS customer_name,
    o.o_orderkey,
    o.o_orderdate,
    sc.s_name AS supplier_name,
    hcs.total_supply_cost
FROM
    orders o
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    part p ON l.l_partkey = p.p_partkey
JOIN
    HighCostSuppliers hcs ON p.p_name = hcs.s_name
JOIN
    supplier sc ON sc.s_suppkey = (
        SELECT s.s_suppkey
        FROM supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        WHERE ps.ps_partkey = l.l_partkey
        ORDER BY ps.ps_supplycost * ps.ps_availqty DESC
        LIMIT 1
    )
WHERE
    o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
ORDER BY
    hcs.total_supply_cost DESC;
