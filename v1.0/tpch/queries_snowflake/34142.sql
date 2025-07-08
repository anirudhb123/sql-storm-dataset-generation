WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal BETWEEN 5000 AND 10000
), 

PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, COALESCE(ps.ps_availqty, 0) AS ps_availqty
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),

CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, SUM(o.o_totalprice) AS total_spent, 
           DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
)

SELECT ph.s_name AS supplier_name, 
       COALESCE(pd.p_name, 'Unknown Part') AS part_name, 
       pd.p_retailprice AS retail_price, 
       COALESCE(c.total_spent, 0) AS customer_spending,
       CONCAT('Region: ', r.r_name) AS region_info, 
       CASE WHEN c.spending_rank <= 3 THEN 'Top Customer' ELSE 'Regular Customer' END AS customer_type
FROM SupplierHierarchy ph
JOIN supplier s ON ph.s_suppkey = s.s_suppkey
LEFT JOIN PartDetails pd ON s.s_suppkey = pd.p_partkey 
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN CustomerOrders c ON s.s_nationkey = c.c_nationkey
WHERE pd.ps_availqty IS NOT NULL 
  AND pd.p_retailprice > 50.00 
ORDER BY supplier_name, part_name;
