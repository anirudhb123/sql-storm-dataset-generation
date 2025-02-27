WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier AS s
    WHERE s.s_nationkey IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier AS s
    JOIN SupplierHierarchy AS sh ON s.s_nationkey = sh.s_nationkey
)
, CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM customer AS c
    LEFT JOIN orders AS o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
, PartSupply AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part AS p
    JOIN partsupp AS ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    c.c_custkey,
    c.c_name,
    co.total_spent,
    co.order_count,
    p.p_partkey,
    p.p_name,
    ps.total_available,
    ps.avg_supplycost,
    CASE 
        WHEN co.total_spent > 1000 THEN 'High Value Customer'
        WHEN co.total_spent IS NULL THEN 'No Orders'
        ELSE 'Regular Customer'
    END AS customer_status,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY co.total_spent DESC) AS rank_per_nation
FROM CustomerOrders AS co
FULL OUTER JOIN nation AS n ON co.c_custkey IS NOT NULL
LEFT JOIN PartSupply AS ps ON ps.total_available IS NOT NULL
JOIN part AS p ON p.p_partkey = ps.p_partkey
WHERE 
    (p.p_size BETWEEN 5 AND 20 OR p.p_container = 'BOX') AND
    (co.total_spent IS NOT NULL OR co.order_count > 0)
ORDER BY 
    co.total_spent DESC NULLS LAST,
    p.p_name;
