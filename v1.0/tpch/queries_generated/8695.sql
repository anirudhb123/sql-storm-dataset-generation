WITH SupplierCost AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 50000
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    n.n_name AS nation_name, 
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    SUM(sc.total_cost) AS total_supplier_cost,
    SUM(hvc.total_spent) AS total_customer_spending
FROM NationRegion n
JOIN HighValueCustomers hvc ON n.n_nationkey = hvc.c_custkey
JOIN SupplierCost sc ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = hvc.c_custkey)
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY n.n_name, r.r_name
ORDER BY total_supplier_cost DESC, total_customer_spending DESC
LIMIT 10;
