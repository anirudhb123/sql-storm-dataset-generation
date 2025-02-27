WITH RECURSIVE cust_order_history AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN cust_order_history co ON co.o_orderkey = o.o_orderkey
    WHERE o.o_orderdate < co.o_orderdate
),
supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_avail_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
region_sales AS (
    SELECT r.r_regionkey, r.r_name, SUM(o.o_totalprice) AS total_sales
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    c.c_name AS customer_name,
    SUM(o.o_totalprice) AS total_order_value,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END) AS total_returned_price,
    s.s_name AS supplier_name,
    r.r_name AS region_name,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rank,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COALESCE(NULLIF(MAX(l.l_discount), 0), 'No Discount') AS applicable_discount,
    STRING_AGG(DISTINCT l.l_shipmode, ', ') AS shipping_modes
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN supplier_summary s ON l.l_suppkey = s.s_suppkey
LEFT JOIN region_sales r ON c.c_nationkey = r.r_regionkey
WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY c.c_custkey, c.c_name, s.s_name, r.r_name
HAVING SUM(o.o_totalprice) > 10000
ORDER BY total_order_value DESC, customer_name;
