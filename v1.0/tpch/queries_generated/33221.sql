WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 0 AS level
    FROM customer c
    WHERE c.c_nationkey IN (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_name = 'USA'
    )
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 5
), 
RecentOrders AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY o.o_custkey
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
LineItemStats AS (
    SELECT l.l_partkey, SUM(l.l_quantity) AS total_quantity, 
           AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_sales
    FROM lineitem l
    GROUP BY l.l_partkey
)

SELECT 
    p.p_name, 
    c.c_name AS customer_name,
    CASE 
        WHEN ch.level IS NULL THEN 'General Customer'
        ELSE 'VIP Customer'
    END AS customer_status,
    sd.avg_supplycost,
    lis.total_quantity,
    lis.avg_sales,
    COALESCE(ro.total_spent, 0) AS total_spent_last_year
FROM part p
LEFT JOIN LineItemStats lis ON p.p_partkey = lis.l_partkey
LEFT JOIN SupplierDetails sd ON sd.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey = p.p_partkey
    ORDER BY ps.ps_supplycost ASC 
    LIMIT 1
)
LEFT JOIN RecentOrders ro ON ro.o_custkey = (
    SELECT o.o_custkey 
    FROM orders o 
    INNER JOIN lineitem li ON o.o_orderkey = li.l_orderkey 
    WHERE li.l_partkey = p.p_partkey 
    LIMIT 1
)
LEFT JOIN CustomerHierarchy ch ON ch.c_custkey = ro.o_custkey
ORDER BY total_spent_last_year DESC, p.p_retailprice DESC
LIMIT 100;
