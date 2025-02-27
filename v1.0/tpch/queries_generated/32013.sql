WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 0 AS level
    FROM customer c
    WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
),
RegionExpenses AS (
    SELECT r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_expense
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY r.r_name
),
RankedExpenses AS (
    SELECT r.*, DENSE_RANK() OVER (ORDER BY total_expense DESC) AS rnk
    FROM RegionExpenses r
)
SELECT r.r_name, COALESCE(total_expense, 0) AS total_expense, 
       ch.c_name, 
       ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY total_expense DESC) AS customer_rank
FROM RankedExpenses r
LEFT JOIN CustomerHierarchy ch ON ch.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
WHERE rnk <= 5
ORDER BY r.r_name, customer_rank;
