WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_nationkey, s_name, s_suppkey, s_acctbal
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.n_nationkey, sup.s_name, sup.s_suppkey, sup.s_acctbal
    FROM SupplierHierarchy sh
    JOIN supplier sup ON sup.s_nationkey = sh.s_nationkey
    JOIN nation n ON n.n_nationkey = sh.s_nationkey
    WHERE sup.s_acctbal < sh.s_acctbal
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spending
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RankedCustomers AS (
    SELECT *,
           RANK() OVER (ORDER BY total_spending DESC) AS spending_rank
    FROM CustomerOrders
)
SELECT n.n_name, 
       COALESCE(SUM(ps.total_avail_qty), 0) AS available_quantity,
       COALESCE(SUM(ps.avg_supply_cost), 0) AS avg_supply_cost,
       COALESCE(COUNT(DISTINCT rc.c_custkey), 0) AS customer_count,
       ARRAY_AGG(DISTINCT rc.c_name) AS customer_names
FROM nation n
LEFT JOIN PartStats ps ON n.n_nationkey = (
    SELECT s_nationkey FROM supplier s
    WHERE s.s_suppkey IN 
        (SELECT s_suppkey FROM SupplierHierarchy WHERE s_acctbal > 15000)
) 
LEFT JOIN RankedCustomers rc ON rc.c_custkey IN (
    SELECT o.o_custkey FROM orders o
    WHERE o.o_orderstatus = 'F' AND o.o_totalprice > 500
)
GROUP BY n.n_nationkey, n.n_name
HAVING COUNT(DISTINCT rc.c_custkey) > 0
ORDER BY n.n_name;
