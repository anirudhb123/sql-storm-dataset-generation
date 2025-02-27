WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    UNION ALL
    SELECT o.orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE oh.level < 5
),
CustomerSpend AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierAvgCost AS (
    SELECT ps.ps_suppkey, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
PartSuppliers AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
RecentOrders AS (
    SELECT DISTINCT o.o_orderkey, o.o_orderdate
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '30 days'
),
RankedCustomers AS (
    SELECT 
        c.c_custkey, c.c_name, ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM CustomerSpend cs
    JOIN customer c ON cs.c_custkey = c.c_custkey
)
SELECT 
    r.rank,
    c.c_name,
    ps.p_name,
    ps.num_suppliers,
    ac.avg_supply_cost,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM RankedCustomers r
JOIN customer c ON r.c_custkey = c.c_custkey
JOIN lineitem l ON l.l_orderkey IN (SELECT o_orderkey FROM RecentOrders)
LEFT JOIN PartSuppliers ps ON l.l_partkey = ps.p_partkey
LEFT JOIN SupplierAvgCost ac ON l.l_suppkey = ac.ps_suppkey
WHERE c.c_acctbal IS NOT NULL
AND ps.num_suppliers > 5
GROUP BY r.rank, c.c_name, ps.p_name, ps.num_suppliers, ac.avg_supply_cost
ORDER BY r.rank, total_revenue DESC;
