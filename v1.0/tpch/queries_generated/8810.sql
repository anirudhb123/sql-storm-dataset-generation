WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01' 
      AND o.o_orderdate < DATE '2023-10-01'
),
TopCustomers AS (
    SELECT r.r_name, SUM(ro.o_totalprice) AS total_spent
    FROM RankedOrders ro
    JOIN nation n ON ro.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE ro.rn <= 5
    GROUP BY r.r_name
),
AverageSpent AS (
    SELECT AVG(total_spent) AS avg_spending
    FROM TopCustomers
)
SELECT rc.r_name, tc.total_spent, (tc.total_spent - as.avg_spending) AS spending_difference
FROM TopCustomers tc
CROSS JOIN AverageSpent as
JOIN region rc ON rc.r_name = tc.r_name
WHERE tc.total_spent > as.avg_spending
ORDER BY spending_difference DESC;
