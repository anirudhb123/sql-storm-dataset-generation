WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
), 
AggregateOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE o.o_orderdate >= '2023-01-01' 
      AND o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey
), 
RevenuePerCustomer AS (
    SELECT c.c_custkey, c.c_name, SUM(a.total_revenue) AS total_spent
    FROM customer c
    LEFT JOIN AggregateOrders a ON c.c_custkey = a.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierInfo AS (
    SELECT r.r_name, n.n_name, s.s_name, SUM(p.ps_supplycost * p.ps_availqty) AS total_supply_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp p ON s.s_suppkey = p.ps_suppkey
    GROUP BY r.r_name, n.n_name, s.s_name
)

SELECT 
    rc.c_custkey,
    rc.c_name,
    COALESCE(sp.total_spent, 0) AS total_spent,
    COALESCE(su.total_supply_cost, 0) AS total_supply_cost,
    ROW_NUMBER() OVER (ORDER BY COALESCE(sp.total_spent, 0) DESC) AS customer_rank
FROM RevenuePerCustomer sp
FULL OUTER JOIN SupplierInfo su ON sp.c_name = su.s_name
JOIN region r ON r.r_name = su.r_name
WHERE (total_spent > 10000 OR total_supply_cost > 5000)
  AND r.r_name IS NOT NULL
ORDER BY customer_rank ASC;
