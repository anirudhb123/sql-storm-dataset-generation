WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_nationkey = nh.n_regionkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
MaxSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty
)
SELECT r.r_name,
       COUNT(DISTINCT c.c_custkey) AS num_customers,
       AVG(cos.total_spent) AS avg_spent_per_customer,
       COUNT(DISTINCT ms.ps_suppkey) AS num_suppliers,
       SUM(CASE WHEN ms.total_revenue IS NULL THEN 0 ELSE ms.total_revenue END) AS total_revenue
FROM region r
LEFT JOIN nation nh ON r.r_regionkey = nh.n_regionkey
LEFT JOIN customer c ON c.c_nationkey = nh.n_nationkey
LEFT JOIN CustomerOrderStats cos ON c.c_custkey = cos.c_custkey
LEFT JOIN MaxSupplier ms ON ms.ps_partkey = (
    SELECT p.p_partkey 
    FROM part p 
    WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2 
        WHERE p2.p_container IS NOT NULL
    )
    ORDER BY p.p_retailprice DESC
    LIMIT 1
)
GROUP BY r.r_name
ORDER BY r.r_name;
