WITH RECURSIVE supply_chain AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name,
        s.s_acctbal,
        1 AS level
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE
        ps.ps_availqty > 0

    UNION ALL

    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name,
        s.s_acctbal,
        sc.level + 1
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN
        supply_chain sc ON ps.ps_partkey = sc.ps_partkey
    WHERE
        ps.ps_availqty > 0 AND sc.level < 5
),
total_cost AS (
    SELECT
        p.p_partkey,
        SUM(sc.ps_supplycost * sc.ps_availqty) AS total_supply_cost
    FROM
        part p
    LEFT JOIN
        supply_chain sc ON p.p_partkey = sc.ps_partkey
    GROUP BY
        p.p_partkey
),
customer_orders AS (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY
        c.c_custkey
)
SELECT
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS revenue,
    AVG(tc.total_supply_cost) AS avg_supply_cost,
    SUM("total_spent") AS total_spent_by_customers
FROM
    nation n
JOIN
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN
    total_cost tc ON tc.p_partkey = (SELECT ps.ps_partkey 
                                      FROM partsupp ps 
                                      WHERE ps.ps_suppkey = o.o_orderkey 
                                      LIMIT 1)
GROUP BY
    r.r_name
ORDER BY
    total_spent_by_customers DESC
LIMIT 10;
