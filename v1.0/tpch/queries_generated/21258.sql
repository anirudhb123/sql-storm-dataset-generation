WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
), 
supply_info AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        (ps.ps_supplycost + CASE WHEN ps.ps_availqty = 0 THEN 0 ELSE ps.ps_supplycost * 0.05 END) AS supply_cost_adjusted,
        COALESCE(NULLIF(p.p_name, ''), 'Unknown Part') AS part_name
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
), 
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL OR COUNT(DISTINCT o.o_orderkey) < 5
)
SELECT 
    c.c_name,
    SUM(supply_info.supply_cost_adjusted) AS total_supply_cost,
    COUNT(DISTINCT ranked_orders.o_orderkey) OVER (PARTITION BY c.c_custkey) AS total_orders_count,
    STRING_AGG(DISTINCT supply_info.part_name, ', ') AS supplied_parts
FROM customer_summary c
LEFT JOIN ranked_orders ON TRUE
LEFT JOIN supply_info ON supply_info.ps_partkey IN (
    SELECT s.ps_partkey 
    FROM supply_info s 
    WHERE s.ps_availqty > 0
) 
WHERE c.total_spent > 1000.00 OR (SELECT COUNT(*) FROM orders o WHERE o.o_orderkey = ranked_orders.o_orderkey AND o.o_orderstatus = 'O') > 0
GROUP BY c.c_custkey, c.c_name
HAVING COUNT(DISTINCT supply_info.part_name) > 5 OR MAX(ranked_orders.order_rank) < 10
ORDER BY total_supply_cost DESC, c.c_name ASC;
