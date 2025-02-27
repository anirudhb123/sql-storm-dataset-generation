WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    INNER JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
MaxOrderCount AS (
    SELECT 
        MAX(order_count) AS max_count
    FROM CustomerOrderCount
)
SELECT 
    RANK() OVER (ORDER BY roc.order_count DESC) AS customer_rank,
    c.c_name,
    c.c_addr AS address,
    roc.order_count,
    s.s_name AS supplier_name,
    ps.total_supply_cost,
    CASE 
        WHEN roc.order_count = mc.max_count THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM CustomerOrderCount roc
JOIN customer c ON roc.c_custkey = c.c_custkey
LEFT JOIN SupplierCosts ps ON ps.ps_partkey = (
    SELECT l.l_partkey
    FROM lineitem l
    WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM RankedOrders)
    LIMIT 1
)
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN MaxOrderCount mc ON roc.order_count = mc.max_count
WHERE 
    ps.total_supply_cost IS NOT NULL
    AND n.n_name IS NOT NULL
ORDER BY customer_rank, ps.total_supply_cost DESC;
