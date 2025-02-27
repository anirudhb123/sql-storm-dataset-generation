WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rank_by_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
CustomerOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_custkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_custkey
),
HighValueSuppliers AS (
    SELECT s_name, s_acctbal
    FROM RankedSuppliers
    WHERE rank_by_cost = 1 AND s_acctbal > 100000
),
TopCustomers AS (
    SELECT DISTINCT c.c_custkey, c.c_name, co.total_revenue
    FROM customer c
    JOIN CustomerOrders co ON c.c_custkey = co.o_custkey
    WHERE co.revenue_rank <= 10
)
SELECT 
    p.p_name,
    COALESCE(hvs.s_name, 'No Supplier') AS supplier_name,
    COALESCE(tcu.c_name, 'No Customer') AS customer_name,
    AVG(l.l_extendedprice) AS avg_extended_price,
    SUM(l.l_discount) AS total_discount,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN HighValueSuppliers hvs ON ps.ps_suppkey = hvs.s_suppkey
LEFT JOIN CustomerOrders co ON l.l_orderkey = co.o_orderkey
LEFT JOIN TopCustomers tcu ON co.o_custkey = tcu.c_custkey
WHERE p.p_retailprice > 50 AND (l.l_discount IS NOT NULL OR l.l_discount < 0.2)
GROUP BY p.p_name, hvs.s_name, tcu.c_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY avg_extended_price DESC, total_discount ASC;
