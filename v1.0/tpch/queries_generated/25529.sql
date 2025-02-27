WITH SupplierWithAvgSupplyCost AS (
    SELECT s.s_suppkey, s.s_name, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
PartsWithComments AS (
    SELECT p.p_partkey, p.p_name, p.p_comment, 
           LENGTH(TRIM(p.p_comment)) AS comment_length,
           SUBSTRING(TRIM(p.p_comment) FROM 1 FOR 10) AS short_comment
    FROM part p
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighSpendingCustomers AS (
    SELECT c.c_custkey, c.c_name, c.total_orders, c.total_spent
    FROM CustomerOrderDetails c
    WHERE c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderDetails)
)
SELECT s.s_name AS supplier_name, p.p_name AS part_name, 
       pc.comment_length AS comment_length, h.total_orders AS total_orders,
       h.total_spent AS total_spent, s.avg_supply_cost AS average_supply_cost
FROM SupplierWithAvgSupplyCost s
JOIN PartsWithComments pc ON s.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = (SELECT p.p_partkey 
                           FROM part p 
                           WHERE LENGTH(TRIM(p.p_comment)) > 0 
                           ORDER BY RANDOM() LIMIT 1)
)
JOIN HighSpendingCustomers h ON h.c_custkey = (
    SELECT o.o_custkey
    FROM orders o 
    ORDER BY RANDOM() LIMIT 1
)
ORDER BY s.avg_supply_cost DESC, h.total_spent DESC;
