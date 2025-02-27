WITH RECURSIVE CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS order_level
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT
        co.c_custkey,
        co.c_name,
        co.c_acctbal,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        co.order_level + 1
    FROM
        CustomerOrders co
    JOIN
        orders o ON co.o_orderkey = o.o_orderkey
    WHERE
        co.order_level < 5
),
PartSupplier AS (
    SELECT
        ps.ps_supplycost,
        p.p_container,
        p.p_size,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM
        partsupp ps
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT
    co.c_name,
    SUM(co.o_totalprice) AS total_spent,
    AVG(co.o_totalprice) AS avg_order_value,
    ps.p_container,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    COUNT(DISTINCT co.o_orderkey) AS order_count
FROM
    CustomerOrders co
LEFT JOIN
    PartSupplier ps ON ps.rank = 1
WHERE
    co.c_acctbal IS NOT NULL
    AND co.o_orderdate >= DATE '2022-01-01'
    AND NOT (co.o_totalprice < 100 AND ps.p_size < 20)
GROUP BY
    co.c_name, ps.p_container
HAVING
    total_spent > 5000
ORDER BY
    total_spent DESC;
