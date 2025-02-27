WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrder AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '2023-01-01'
    GROUP BY c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ps.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(ps.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(co.total_spent, 0) AS customer_total_spent,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY COALESCE(co.total_spent, 0) DESC) AS rank,
    CASE 
        WHEN co.order_count > 10 THEN 'Frequent Customer'
        WHEN co.order_count BETWEEN 1 AND 10 THEN 'Occasional Customer'
        ELSE 'No Orders'
    END AS customer_status
FROM part p
LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN CustomerOrder co ON co.c_custkey IN (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_nationkey IN (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'Europe')
    )
)
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_brand = p.p_brand)
ORDER BY p.p_partkey;
