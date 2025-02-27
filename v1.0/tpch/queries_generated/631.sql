WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
OrderLineItems AS (
    SELECT l.o_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount,
           SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY l.o_orderkey) AS total_price_after_discount
    FROM lineitem l
    WHERE l.l_shipdate >= '2022-01-01' AND l.l_shipdate < '2023-01-01'
),
Suppliers AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, p.p_brand, SUM(ps.ps_availqty) AS total_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey, p.p_name, p.p_brand
),
FilteredResults AS (
    SELECT co.c_custkey, co.c_name, ol.o_orderkey, ol.total_price_after_discount,
           s.s_name AS supplier_name, s.total_availqty
    FROM CustomerOrders co
    LEFT JOIN OrderLineItems ol ON co.o_orderkey = ol.o_orderkey
    LEFT JOIN Suppliers s ON ol.l_partkey = s.p_partkey
    WHERE co.order_rank <= 5 AND (s.total_availqty IS NULL OR s.total_availqty > 100)
)
SELECT fr.c_custkey, fr.c_name, COUNT(fr.o_orderkey) AS order_count,
       AVG(fr.total_price_after_discount) AS avg_order_value,
       STRING_AGG(DISTINCT fr.supplier_name, ', ') AS suppliers
FROM FilteredResults fr
GROUP BY fr.c_custkey, fr.c_name
HAVING AVG(fr.total_price_after_discount) > 500
ORDER BY order_count DESC, avg_order_value DESC;
