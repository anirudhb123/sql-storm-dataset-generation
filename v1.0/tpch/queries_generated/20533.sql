WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
FilteredSuppliers AS (
    SELECT
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_value
    FROM RankedSuppliers rs
    WHERE rs.rank <= 3
),
CustomerAggregate AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
Max订单 AS (
    SELECT
        MAX(total_orders_value) AS max_orders_value
    FROM CustomerAggregate
)
SELECT
    fs.s_suppkey,
    fs.s_name,
    COALESCE(ca.total_orders_value, 0) AS total_customer_orders,
    CASE 
        WHEN ca.total_orders_value IS NULL THEN 'No Orders'
        WHEN ca.total_orders_value > (SELECT max_orders_value FROM Max订单) * 0.1 THEN 'High Value'
        ELSE 'Low Value'
    END AS order_status
FROM FilteredSuppliers fs
LEFT JOIN CustomerAggregate ca ON fs.total_supply_value > ca.total_orders_value
WHERE fs.total_supply_value IS NOT NULL
ORDER BY fs.total_supply_value DESC, order_status ASC
LIMIT 10;
