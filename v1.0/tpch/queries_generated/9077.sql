WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(co.total_spent) AS total_spent
    FROM CustomerOrders co
    JOIN customer c ON co.c_custkey = c.c_custkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
),
SupplierDetails AS (
    SELECT sp.s_suppkey, sp.s_name, COUNT(DISTINCT tp.o_orderkey) AS order_count, SUM(tp.total_spent) AS total_sales
    FROM SupplierParts sp
    JOIN CustomerOrders tp ON tp.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE l.l_partkey IN (SELECT DISTINCT p_partkey FROM part)
    )
    GROUP BY sp.s_suppkey, sp.s_name
)
SELECT DISTINCT
    tc.c_custkey,
    tc.c_name AS customer_name,
    sd.s_suppkey,
    sd.s_name AS supplier_name,
    sd.order_count,
    sd.total_sales
FROM TopCustomers tc
JOIN SupplierDetails sd ON tc.total_spent > sd.total_sales
WHERE sd.order_count > 5
ORDER BY sd.total_sales DESC, tc.total_spent DESC;
