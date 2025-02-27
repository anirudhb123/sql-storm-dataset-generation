WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS lvl
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.lvl + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.lvl < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartStats AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_acct_bal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    nh.n_name,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    SUM(NVLA.total_avail_qty) AS total_avail_qty,
    AVG(NVLA.avg_supply_cost) AS avg_supply_cost,
    MAX(co.order_count) AS max_orders
FROM NationSummary nh
LEFT JOIN SupplierHierarchy sh ON nh.n_nationkey = sh.s_nationkey
LEFT JOIN PartStats NVLA ON NVLA.total_avail_qty IS NOT NULL
LEFT JOIN CustomerOrders co ON co.c_custkey = (SELECT MIN(c.c_custkey) FROM customer c WHERE c.c_nationkey = nh.n_nationkey)
GROUP BY nh.n_name
HAVING SUM(NVLA.total_avail_qty) > 1000
ORDER BY supplier_count DESC NULLS LAST;
