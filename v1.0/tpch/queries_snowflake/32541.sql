WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL

    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, co.level + 1
    FROM CustomerOrders co
    JOIN orders o ON co.o_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE co.level < 10
),
AggregateOrderData AS (
    SELECT co.c_custkey, co.c_name,
           COUNT(DISTINCT co.o_orderkey) AS order_count,
           SUM(co.o_totalprice) AS total_spent,
           MIN(co.o_orderdate) AS first_order_date
    FROM CustomerOrders co
    GROUP BY co.c_custkey, co.c_name
),
TopCustomers AS (
    SELECT *
    FROM AggregateOrderData
    ORDER BY total_spent DESC
    LIMIT 10
),
SupplierPartPrice AS (
    SELECT ps.ps_partkey, s.s_suppkey, s.s_name, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT tc.c_custkey, tc.c_name, tc.order_count, tc.total_spent, tc.first_order_date,
       sp.s_name, sp.ps_supplycost
FROM TopCustomers tc
LEFT JOIN SupplierPartPrice sp ON tc.c_custkey = sp.ps_partkey
WHERE sp.rank = 1 OR sp.rank IS NULL
ORDER BY tc.total_spent DESC, tc.order_count DESC;
