WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O' 
    AND EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_orderkey = o.o_orderkey 
        AND l.l_discount > 0.05
    )
)
SELECT 
    n.n_name,
    SUM(COALESCE(fo.o_totalprice, 0)) AS total_customer_orders,
    AVG(ps.total_supply_cost) AS avg_supply_cost,
    COUNT(DISTINCT sh.s_suppkey) AS num_suppliers
FROM nation n
LEFT JOIN FilteredOrders fo ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = fo.o_custkey)
LEFT JOIN PartSupplier ps ON ps.p_partkey IN (
    SELECT l.l_partkey
    FROM lineitem l
    WHERE l.l_orderkey = fo.o_orderkey
) 
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
GROUP BY n.n_name
HAVING total_customer_orders > 10000
ORDER BY total_customer_orders DESC
OFFSET 5 ROWS;
