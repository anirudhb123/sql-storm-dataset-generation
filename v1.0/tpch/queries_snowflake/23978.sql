
WITH CustomerPurchases AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT c.c_custkey,
           c.c_name,
           cp.total_spent,
           RANK() OVER (ORDER BY cp.total_spent DESC) AS rank
    FROM CustomerPurchases cp
    JOIN customer c ON cp.c_custkey = c.c_custkey
    WHERE cp.total_spent IS NOT NULL
),
PartSupplierData AS (
    SELECT p.p_partkey,
           p.p_name,
           ps.ps_supplycost,
           SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, ps.ps_supplycost
)
SELECT tc.c_name,
       ps.p_name,
       ps.ps_supplycost,
       ps.total_available,
       CASE
           WHEN total_spent IS NULL THEN 'No Orders'
           ELSE total_spent::TEXT
       END AS total_spent,
       COALESCE(tc.rank, 10) AS customer_rank
FROM TopCustomers tc
FULL OUTER JOIN PartSupplierData ps ON tc.c_custkey = ps.p_partkey
WHERE (tc.total_spent > 1000 OR ps.ps_supplycost < 20.00)
  AND (tc.rank IS NOT NULL OR ps.total_available IS NULL)
ORDER BY customer_rank DESC, ps.p_name
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
