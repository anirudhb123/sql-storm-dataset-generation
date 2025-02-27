WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_totalprice,
        o_orderdate,
        o_orderpriority,
        1 AS level,
        CAST(o_orderkey AS VARCHAR) AS path
    FROM orders
    WHERE o_orderstatus = 'O'
    UNION ALL
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        oh.level + 1,
        CONCAT(oh.path, '->', o.o_orderkey)
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '30' DAY
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierPartStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerSummary AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_orders,
        cs.total_spent,
        sps.total_available_quantity,
        sps.total_supply_value,
        CASE 
            WHEN cs.total_spent IS NULL THEN 'No Orders'
            WHEN cs.total_spent > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS customer_value_status
    FROM CustomerOrderStats cs
    LEFT JOIN SupplierPartStats sps ON cs.total_orders > 5
)
SELECT 
    ch.orderkey,
    cs.c_name,
    cs.total_orders,
    cs.avg_order_value,
    cs.customer_value_status,
    s.s_name AS supplier_name,
    s.total_available_quantity,
    s.total_supply_value
FROM OrderHierarchy ch
JOIN CustomerSummary cs ON ch.o_custkey = cs.c_custkey
JOIN SupplierPartStats s ON cs.total_orders > 5
WHERE s.total_supply_value > 5000
ORDER BY cs.spend_rank, ch.level;
