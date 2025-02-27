WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
AggregatedData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        AVG(ps.ps_supplycost) AS avg_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
),
FinalResults AS (
    SELECT 
        nh.n_name AS nation_name,
        ad.p_name AS part_name,
        co.c_name AS customer_name,
        ad.total_cost,
        co.order_count,
        co.total_spent
    FROM AggregatedData ad
    JOIN CustomerOrders co ON co.total_spent > 1000
    LEFT JOIN nation n ON co.c_nationkey = n.n_nationkey
    JOIN Region r ON n.n_regionkey = r.r_regionkey
    JOIN NationHierarchy nh ON r.r_regionkey = nh.n_nationkey
)
SELECT 
    nation_name,
    part_name,
    customer_name,
    total_cost,
    order_count,
    total_spent
FROM FinalResults
WHERE total_cost IS NOT NULL
ORDER BY total_spent DESC, total_cost ASC
LIMIT 50;
