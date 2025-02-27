WITH RECURSIVE NationsCTE AS (
    SELECT n_nationkey, n_name, n_regionkey, 
           ROW_NUMBER() OVER (ORDER BY n_name) AS rn
    FROM nation
    WHERE n_comment IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 
           (SELECT COUNT(*) FROM nation WHERE n_regionkey = n.n_regionkey) AS rn
    FROM nation n
    INNER JOIN NationsCTE cte ON cte.n_regionkey = n.n_regionkey
    WHERE cte.rn < 5
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           CASE 
               WHEN s.s_acctbal > 5000 THEN 'High Value'
               WHEN s.s_acctbal BETWEEN 1000 AND 5000 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS ValueSegment
    FROM supplier s
    WHERE s.s_comment LIKE '%India%'
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, SUM(ps.ps_supplycost) AS total_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT p.p_name, p.p_brand, ft.ValueSegment, tc.total_spent,
       ROW_NUMBER() OVER (PARTITION BY ft.ValueSegment ORDER BY tc.total_spent DESC) AS RankWithinSegment
FROM PartDetails p
JOIN FilteredSuppliers ft ON ft.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_quantity < 10
    GROUP BY ps.ps_suppkey 
    HAVING COUNT(DISTINCT l.l_orderkey) > 1
)
LEFT JOIN TopCustomers tc ON tc.c_custkey = ft.s_suppkey
WHERE p.total_supplycost IS NOT NULL
ORDER BY ft.ValueSegment, p.p_name;
