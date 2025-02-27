WITH processed_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        SUBSTRING(s.s_name FROM 1 FOR 10) AS supplier_name_short,
        CONCAT('Total Price: ', CAST(o.o_totalprice AS VARCHAR(20)), ' | Customer: ', c.c_name) AS order_summary
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
)
SELECT 
    p.p_name,
    COUNT(DISTINCT po.o_orderkey) AS total_orders,
    MAX(po.o_totalprice) AS max_order_value,
    STRING_AGG(po.order_summary, '; ') AS all_orders_summary
FROM processed_orders po
JOIN part p ON po.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = po.o_orderkey LIMIT 1)
GROUP BY p.p_name
ORDER BY total_orders DESC
LIMIT 10;
