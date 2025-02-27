WITH RECURSIVE customer_order_summary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = c.c_mktsegment)
),
order_counts AS (
    SELECT
        o_custkey,
        COUNT(o_orderkey) AS total_orders
    FROM
        orders
    GROUP BY
        o_custkey
),
supplier_avg_cost AS (
    SELECT
        ps.s_suppkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        partsupp ps
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY
        ps.s_suppkey
),
lineitem_ranking AS (
    SELECT
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_discount,
        l.l_extendedprice,
        SUM(l.l_extendedprice) OVER (PARTITION BY l.l_orderkey) AS total_order_value,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS lineitem_rank
    FROM
        lineitem l
)
SELECT
    cus.c_name,
    cus.c_acctbal,
    ord.total_orders,
    s.avg_supply_cost,
    li.l_orderkey,
    li.l_partkey,
    li.l_discount,
    li.l_extendedprice,
    li.total_order_value
FROM
    customer_order_summary cus
JOIN
    order_counts ord ON cus.c_custkey = ord.o_custkey
LEFT JOIN
    supplier_avg_cost s ON s.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey
            FROM lineitem_ranking l
            WHERE l.l_orderkey = cus.o_orderkey
        )
    )
JOIN
    lineitem_ranking li ON li.l_orderkey = cus.o_orderkey
WHERE
    (cus.o_orderstatus = 'O' OR cus.o_orderstatus IS NULL)
ORDER BY
    cus.c_acctbal DESC, ord.total_orders ASC, li.l_extendedprice DESC;
