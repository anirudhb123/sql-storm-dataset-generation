WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000.00

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 1000.00
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    p.p_name,
    ps.total_supply_cost,
    c.c_name,
    coalesce(cs.order_count, 0) AS order_count,
    coalesce(cs.total_spent, 0) AS total_spent,
    sh.level AS supplier_level
FROM PartSupplier ps
INNER JOIN part p ON p.p_partkey = ps.p_partkey
LEFT JOIN CustomerOrderSummary cs ON cs.rn = 1
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = p.p_partkey) 
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND p.p_size BETWEEN 10 AND 20
UNION ALL
SELECT 
    'Total' AS p_name,
    SUM(ps.total_supply_cost) AS total_supply_cost,
    'Total Customers' AS c_name,
    COUNT(cs.c_custkey) AS order_count,
    SUM(coalesce(cs.total_spent, 0)) AS total_spent,
    NULL
FROM PartSupplier ps
LEFT JOIN CustomerOrderSummary cs ON cs.order_count > 0
WHERE EXISTS (SELECT 1 FROM lineitem l WHERE l.l_partkey = ps.p_partkey)
GROUP BY ps.p_partkey
ORDER BY 2 DESC, 1;
