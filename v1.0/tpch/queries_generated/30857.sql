WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS depth
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.depth + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE sh.depth < 3
),
MaxOrderPerCustomer AS (
    SELECT o.c_custkey, MAX(o.o_totalprice) AS max_order
    FROM orders o
    GROUP BY o.c_custkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.total_spent,
           RANK() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM CustomerOrders c
)

SELECT r.cust_name,
       CASE 
           WHEN r.total_spent IS NULL THEN 'No Orders'
           ELSE CONCAT('Spent: ', r.total_spent)
       END AS spending_info,
       sh.depth AS supplier_depth,
       pd.total_supply_cost
FROM RankedCustomers r
LEFT JOIN SupplierHierarchy sh ON r.c_custkey = sh.s_suppkey
LEFT JOIN PartDetails pd ON sh.s_suppkey = pd.p_partkey
WHERE r.rank <= 5
ORDER BY r.total_spent DESC NULLS LAST;
