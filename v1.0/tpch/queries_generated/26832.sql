WITH supplier_parts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with availability of ', ps.ps_availqty, ' and a supply cost of ', ps.ps_supplycost) AS supplier_details
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
customer_orders AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey AS order_key,
        o.o_totalprice AS total_price,
        CONCAT(c.c_name, ' placed an order with key ', o.o_orderkey, ' totaling ', o.o_totalprice) AS order_details
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
lineitem_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_items
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    sp.supplier_details,
    co.order_details,
    ls.total_revenue,
    ls.total_items
FROM supplier_parts sp
JOIN customer_orders co ON TRUE
JOIN lineitem_summary ls ON co.order_key = ls.o_orderkey
WHERE sp.available_quantity > 100 AND co.total_price > 5000
ORDER BY ls.total_revenue DESC, sp.supplier_name;
