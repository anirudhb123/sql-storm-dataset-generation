WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, 1 AS depth
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL

    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, oh.depth + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey 
    WHERE o.o_orderstatus = 'O' AND oh.depth < 5
),
SupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerSpend AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, cs.total_spent
    FROM CustomerSpend cs
    JOIN customer c ON c.c_custkey = cs.c_custkey
    WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSpend)
    ORDER BY cs.total_spent DESC
    LIMIT 10
)
SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) DESC) AS part_rank,
    COUNT(DISTINCT os.o_orderkey) AS order_count
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN OrderHierarchy oh ON oh.o_orderkey = l.l_orderkey
LEFT JOIN TopCustomers tc ON tc.c_custkey = oh.o_custkey
LEFT JOIN SupplierStats ss ON ss.ps_partkey = p.p_partkey
WHERE p.p_container IS NOT NULL
GROUP BY p.p_partkey, p.p_name, p.p_retailprice
HAVING total_revenue > 1000 AND part_rank < 5
ORDER BY total_revenue DESC, p.p_name;
