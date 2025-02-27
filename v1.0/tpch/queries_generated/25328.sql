WITH supplier_part_details AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty,
           CONCAT(s.s_name, ' supplies ', p.p_name, ' with a cost of ', FORMAT(ps.ps_supplycost, 2), 
           ' and available quantity ', ps.ps_availqty) AS supply_info
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
customer_order_details AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           STRING_AGG(CONCAT('OrderID: ', o.o_orderkey, ' (Total Price: ', FORMAT(o.o_totalprice, 2), ')'), ', ') AS order_summary
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT spd.s_name, spd.p_name, spd.ps_supplycost, cod.c_name, cod.order_count, cod.order_summary,
       CONCAT('Supplier ', spd.s_name, ' has ', cod.order_count, ' orders tied to customer ', cod.c_name) AS customer_info
FROM supplier_part_details spd
JOIN customer_order_details cod ON spd.s_suppkey = (SELECT DISTINCT ps.ps_suppkey 
                                                     FROM partsupp ps 
                                                     JOIN part p ON ps.ps_partkey = p.p_partkey 
                                                     WHERE p.p_name LIKE '%Brass%')
ORDER BY spd.ps_supplycost DESC;
