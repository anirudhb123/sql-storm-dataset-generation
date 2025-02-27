WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal * 1.1, s.n_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.n_nationkey = sh.n_nationkey
    WHERE sh.level < 5
), PartSummary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
), CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent, MAX(o.o_orderdate) AS latest_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
), TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
    FROM CustomerOrderSummary c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 500
)
SELECT 
    p.p_name AS part_name, 
    sh.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    ps.total_available_qty, 
    ps.avg_supply_cost, 
    o.o_orderdate,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Finished'
        WHEN o.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Unknown' 
    END AS order_status,
    COUNT(DISTINCT l.l_orderkey) AS total_orders_for_part,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM PartSummary ps
JOIN lineitem l ON ps.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN TopCustomers c ON o.o_custkey = c.c_custkey
JOIN supplier sh ON l.l_suppkey = sh.s_suppkey
WHERE ps.total_available_qty > 0
GROUP BY p.p_name, sh.s_name, c.c_name, ps.total_available_qty, ps.avg_supply_cost, o.o_orderdate, o.o_orderstatus
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY total_revenue DESC, order_status;
