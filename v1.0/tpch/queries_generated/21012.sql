WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(co.total_revenue) AS customer_total_revenue,
           RANK() OVER (ORDER BY SUM(co.total_revenue) DESC) AS customer_rank
    FROM customer c
    JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(co.total_revenue) > (SELECT AVG(total_revenue) FROM CustomerOrders)
),
SupplierParts AS (
    SELECT ps.ps_partkey, s.s_suppkey, s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_suppkey, s.s_name
),
OrdersWithNull AS (
    SELECT o.o_orderkey, COALESCE(o.o_totalprice, 0) AS safe_totalprice,
           COALESCE(NULLIF(o.o_orderstatus, 'O'), 'Unknown') AS order_status,
           ROW_NUMBER() OVER (ORDER BY o.o_orderdate) AS order_sequence
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
)
SELECT tc.c_name, tc.customer_total_revenue,
       sp.s_name AS supplier_name, sp.total_cost,
       ow.safe_totalprice, ow.order_status, ow.order_sequence
FROM TopCustomers tc
CROSS JOIN SupplierParts sp
LEFT JOIN OrdersWithNull ow ON ow.o_orderkey = (
    SELECT o_orderkey FROM orders WHERE o_custkey = tc.c_custkey
    ORDER BY o_orderdate DESC LIMIT 1
)
WHERE tc.customer_rank <= 5 AND sp.total_cost IS NOT NULL
ORDER BY customer_total_revenue DESC, supplier_name, safe_totalprice;
