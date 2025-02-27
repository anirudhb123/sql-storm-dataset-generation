WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, sh.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < 5000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
AvgOrderValue AS (
    SELECT c.custkey, AVG(total_spent) as avg_spent
    FROM (
        SELECT co.c_custkey, COALESCE(co.total_spent, 0) AS total_spent
        FROM customer c
        LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    ) AS cust_totals
    GROUP BY cust_totals.c_custkey 
),
PartProfit AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS profit
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey
)
SELECT 
    r.r_name AS region,
    ns.n_name AS nation,
    CONCAT('Supplier: ', sh.s_name, ', Account Balance: ', sh.s_acctbal) AS supplier_info,
    AVG(a.avg_spent) AS average_customer_spending,
    SUM(pp.profit) AS total_profit FROM SupplierHierarchy sh
JOIN nation ns ON sh.s_nationkey = ns.n_nationkey
JOIN region r ON ns.n_regionkey = r.r_regionkey
LEFT JOIN AvgOrderValue a ON sh.s_nationkey = a.custkey
LEFT JOIN PartProfit pp ON pp.p_partkey IN 
    (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sh.s_suppkey)
WHERE a.avg_spent IS NOT NULL
GROUP BY r.r_name, ns.n_name, sh.s_suppkey, sh.s_name, sh.s_acctbal
ORDER BY total_profit DESC NULLS LAST;
