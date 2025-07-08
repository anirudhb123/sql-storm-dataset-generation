WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
SupplierWithMaxCost AS (
    SELECT ps_suppkey, MAX(ps_supplycost) AS max_supplycost
    FROM partsupp
    GROUP BY ps_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT
    r.r_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(c.total_spent) AS avg_customer_spent,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    SUM(CASE WHEN l.l_discount > 0.05 THEN l.l_extendedprice * (1 - l.l_discount) END) AS total_discounted_sales,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity
FROM
    region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN SupplierWithMaxCost smc ON s.s_suppkey = smc.ps_suppkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN CustomerOrders c ON s.s_suppkey = c.c_custkey
WHERE
    ps.ps_availqty > 10
    AND (s.s_acctbal IS NOT NULL OR s.s_name LIKE 'Supplier%')
GROUP BY r.r_name
ORDER BY r.r_name DESC;
